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

        @custom_initialize = options[:custom_initialize].nil? ? false : !!options[:custom_initialize]

        @id_method = (options[:id_method] || repository.id_method).to_sym
        @access_method = (options[:access_method] || Reality::Naming.pluralize(@key)).to_sym
        @inverse_access_method = (options[:inverse_access_method] || @key).to_sym
        @container_key = container_key.nil? ? nil : container_key.to_sym

        {
          :key => @key,
          :id_method => @id_method,
          :access_method => @access_method,
          :inverse_access_method => @inverse_access_method,
        }.each_pair do |attribute_name, value|
          unless Reality::Naming.underscore?(value)
            Reality::Model.error("Model Element '#{qualified_key}' has a #{attribute_name} '#{value}' that does not use the underscore naming pattern (i.e. The #{attribute_name} should be '#{Reality::Naming.underscore(value)}').")
          end
        end

        unless Reality::Naming.pascal_case?(@model_classname)
          Reality::Model.error("Model Element '#{qualified_key}' has a model_classname '#{@model_classname}' that does not use the pascal case naming pattern (i.e. The model_classname should be '#{Reality::Naming.pascal_case(@model_classname)}').")
        end

        if @container_key && !repository.model_element_by_key?(@container_key)
          Reality::Model.error("Model Element '#{qualified_key}' defines container as '#{@container_key}' but no such model element exists.")
        end

        @repository.send(:register_model_element, self)

        yield self if block_given?
      end

      attr_reader :repository
      attr_reader :key
      attr_reader :container_key
      attr_reader :model_classname
      attr_reader :id_method
      attr_reader :access_method
      attr_reader :inverse_access_method

      def custom_initialize?
        @custom_initialize
      end

      def qualified_key
        "#{repository.key}.#{self.key}"
      end

      private

      def build_child_accessor_code(child)
        # @formatter:off
        code = <<-RUBY

  public

        RUBY
        unless child.custom_initialize?
          code += <<-RUBY
  def #{child.inverse_access_method}(#{child.id_method}, options = {}, &block)
    #{child.model_classname}.new(#{child.id_method}, options, &block)
  end

          RUBY
        end
        code += <<-RUBY
  def #{child.inverse_access_method}_by_#{child.id_method}?(#{child.id_method})
    !!#{child.inverse_access_method}_map[#{child.id_method}.to_s]
  end

  def #{child.inverse_access_method}_by_#{child.id_method}(#{child.id_method})
    #{child.inverse_access_method} = #{child.inverse_access_method}_map[#{child.id_method}.to_s]
    raise "No #{child.key} with #{child.id_method} '\#{#{child.id_method}}' defined." unless #{child.inverse_access_method}
    #{child.inverse_access_method}
  end

  def #{child.access_method}
    #{child.inverse_access_method}_map.values
  end

  private

  def register_#{child.inverse_access_method}(#{child.inverse_access_method})
    #{child.repository.log_container}.error("Attempting to register duplicate #{child.inverse_access_method} definition with #{child.id_method} '\#{#{child.id_method}}'") if #{child.inverse_access_method}_by_#{child.id_method}?(#{child.inverse_access_method}.#{child.id_method})
    #{child.inverse_access_method}_map[#{child.inverse_access_method}.#{child.id_method}.to_s] = #{child.inverse_access_method}
  end

  def #{child.inverse_access_method}_map
    @#{child.inverse_access_method}_map ||= Reality::OrderedHash.new
  end
        RUBY
        # @formatter:on
      end
    end
  end
end
