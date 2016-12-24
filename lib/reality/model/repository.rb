#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Reality #nodoc
  module Model #nodoc

    class Repository
      attr_reader :key

      def initialize(key)
        @key = key
        @locked = false
      end

      def model_element_keys
        model_element_map.keys
      end

      def model_elements
        model_element_map.values
      end

      def model_element_by_key?(key)
        !!model_element_map[key.to_s]
      end

      def model_element_by_key(key)
        model_element = model_element_map[key.to_s]
        Reality::Model.error("Can not find model element '#{key}' in repository '#{self.key}'.") unless model_element
        model_element
      end

      def model_element(key, container_key = nil, options = {})
        ModelElement.new(self, key, container_key, options)
      end

      def model_elements_by_container(container_key)
        model_element_map.values.select { |model_element| model_element.container_key == container_key }
      end

      # This method is called when the repository is finalized, after which no changes can be made.
      def lock!
        Reality::Model.error("Attempting to lock repository '#{key}' when repository is already locked.") if locked?
        @locked = true
      end

      def locked?
        @locked
      end

      private

      def register_model_element(model_element)
        Reality::Model.error("Attempting to define model element '#{model_element.qualified_key}' when repository is locked.") if locked?
        Reality::Model.error("Attempting to redefine model element '#{model_element.qualified_key}'") if model_element_map[model_element.key.to_s]
        model_element_map[model_element.key.to_s] = model_element
      end

      def model_element_map
        @model_element_map ||= {}
      end
    end
  end
end
