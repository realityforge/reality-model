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
      # A symbolic name for the system model
      attr_reader :key
      # The ruby module in which all the model elements will be defined
      attr_reader :model_container
      # The ruby module where the log methods are defined
      attr_reader :log_container
      # The ruby module where the facet manager is defined if any. This will be nil if faceted? returns false.
      attr_reader :facet_container
      # The default name of the method that used as the key or identity field for model. This can
      # be overriden at a model element level.
      attr_reader :id_method

      def initialize(key, model_container, options = {})
        @key = key
        @model_container = model_container
        @log_container = options[:log_container] || model_container
        @facet_container = options[:facet_container]
        @id_method = (options[:id_method] || :name).to_sym
        @faceted = options[:faceted].nil? ? false : !!options[:faceted]
        @locked = false
        if block_given?
          yield self
          lock!
        end
      end

      def faceted?
        !@facet_container.nil?
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
