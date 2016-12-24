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

    # A descriptor describing a base type in the system model.
    class ModelElement
      def initialize(repository, key, container_key, options)
        @repository = repository
        @key = key.to_sym
        @model_classname = (options[:model_classname] || Reality::Naming.pascal_case(key)).to_sym

        @access_method = (options[:access_method] || Reality::Naming.pluralize(@key)).to_sym
        @inverse_access_method = (options[:inverse_access_method] || @key).to_sym
        @container_key = container_key.nil? ? nil : container_key.to_sym

        unless Reality::Naming.underscore?(@key)
          Reality::Model.error("Model Element '#{qualified_key}' has a key '#{key}' that does not use the underscore naming pattern (i.e. The key should be '#{Reality::Naming.underscore(@key)}').")
        end

        if @container_key && !repository.model_element_by_key?(@container_key)
          Reality::Model.error("Model Element '#{qualified_key}' defines container as '#{@container_key}' but no such model element exists.")
        end

        @repository.send(:register_model_element, self)
      end

      attr_reader :repository
      attr_reader :key
      attr_reader :container_key
      attr_reader :model_classname
      attr_reader :access_method
      attr_reader :inverse_access_method

      def qualified_key
        "#{repository.key}.#{self.key}"
      end
    end
  end
end
