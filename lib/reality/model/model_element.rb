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
        Reality::Options.check(options, [:model_classname, :custom_initialize, :id_method, :access_method, :inverse_access_method], Reality::Model, 'create model element')
        @repository = repository
        @key = key.to_sym
        @model_classname = (options[:model_classname] || Reality::Naming.pascal_case(key)).to_sym

        @custom_initialize = options[:custom_initialize].nil? ? false : !!options[:custom_initialize]

        @id_method = (options[:id_method] || repository.default_id_method).to_sym
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

      def model
        self.repository.model_container.const_get(self.model_classname)
      end

      private

      def define_ruby_class(model_container)
        model_container.class_eval(build_model_code)
      end

      def build_model_code
        # @formatter:off
        code = <<-RUBY
class #{self.model_classname}
  attr_reader :#{self.id_method}
        RUBY
        container = self.container_key.nil? ? nil : self.repository.model_element_by_key(self.container_key)
        unless self.container_key.nil?
          code += <<-RUBY
  attr_reader :#{container.inverse_access_method}
          RUBY
        end
        code += <<-RUBY

  def #{self.custom_initialize? ? 'perform_init' : 'initialize'}(#{self.container_key.nil? ? '' : "#{container.inverse_access_method}, "}#{self.id_method}, options = {}, &block)
    @#{self.id_method} = #{self.id_method}
        RUBY
        if self.container_key.nil?
          code += <<-RUBY
    #{self.repository.instance_container}.send(:register_#{self.inverse_access_method}, self)
          RUBY
        else
          code += <<-RUBY
    @#{container.inverse_access_method} = #{container.inverse_access_method}
    @#{container.inverse_access_method}.send(:register_#{self.inverse_access_method}, self)
          RUBY
        end
        if self.repository.faceted?
          code += <<-RUBY
    #{self.repository.facet_container}.target_manager.apply_extension(self)
          RUBY
        end
        code += <<-RUBY
    #{self.repository.log_container}.info "#{self.model_classname} '\#{#{self.id_method}}' definition started."
    pre_init if respond_to?(:pre_init, true)
    self.options = options
    yield self if block_given?
    post_init if respond_to?(:post_init, true)
    #{self.repository.log_container}.info "#{self.model_classname} '\#{#{self.id_method}}' definition completed."
  end
        RUBY

        repository.model_elements_by_container(self.key).each do |child|
          code += build_child_accessor_code(child)
        end

        code += <<-RUBY

  public

  def to_s
    "#{self.model_classname}[\#{self.#{self.id_method}}]"
  end

  def <=>(other)
    self.#{self.id_method} <=> other.#{self.id_method}
  end

  def options=(options)
    options.each_pair do |k, v|
      keys = k.to_s.split('.')
      target = self
      keys[0, keys.length - 1].each do |target_accessor_key|
        target = target.send target_accessor_key.to_sym
      end
      begin
        target.send "\#{keys.last}=", v
      rescue NoMethodError
        raise "Attempted to configure property \\"\#{keys.last}\\" on #{self.model_classname} but property does not exist."
      end
    end
  end
end
        RUBY

        code
      end

      def build_child_accessor_code(child)
        # @formatter:off
        code = <<-RUBY

  public

        RUBY
        unless child.custom_initialize?
          code += <<-RUBY
  def #{child.inverse_access_method}(#{child.id_method}, options = {}, &block)
    #{child.repository.model_container}::#{child.model_classname}.new(#{child.container_key.nil? ? '' : 'self, '}#{child.id_method}, options, &block)
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

  def #{child.inverse_access_method}_#{Reality::Naming.pluralize(child.id_method)}
    #{child.inverse_access_method}_map.keys
  end

  def #{child.access_method}?
    !#{child.inverse_access_method}_map.empty?
  end

  private

  def register_#{child.inverse_access_method}(#{child.inverse_access_method})
    #{child.repository.log_container}.error("Attempting to register duplicate #{child.inverse_access_method} definition with #{child.id_method} '\#{#{child.inverse_access_method}.#{child.id_method}}'") if #{child.inverse_access_method}_by_#{child.id_method}?(#{child.inverse_access_method}.#{child.id_method})
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
