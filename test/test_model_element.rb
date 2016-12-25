require File.expand_path('../helper', __FILE__)

class Reality::Model::TestModelElement < Reality::Model::TestCase
  def test_basic_operation
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer)
    element = Reality::Model::ModelElement.new(repository, :entity, nil, {})

    assert_equal element.repository, repository
    assert_equal element.key, :entity
    assert_equal element.container_key, nil
    assert_equal element.model_classname, :Entity
    assert_equal element.custom_initialize?, false
    assert_equal element.id_method, :name
    assert_equal element.access_method, :entities
    assert_equal element.inverse_access_method, :entity

    assert_equal repository.model_element_by_key?(:entity), true
  end

  def test_default_value_of_id_method
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer, :default_id_method => :key)
    element = Reality::Model::ModelElement.new(repository, :entity, nil, {})

    assert_equal element.id_method, :key
  end

  def test_yield
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer)
    Reality::Model::ModelElement.new(repository, :entity, nil, {}) do |element|

      assert_equal element.repository, repository
      assert_equal element.key, :entity
      assert_equal element.container_key, nil
      assert_equal element.model_classname, :Entity
      assert_equal element.custom_initialize?, false
      assert_equal element.id_method, :name
      assert_equal element.access_method, :entities
      assert_equal element.inverse_access_method, :entity

      assert_equal repository.model_element_by_key?(:entity), true
    end
  end

  def test_basic_operation_with_no_defaults
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer)
    element = Reality::Model::ModelElement.new(repository, :entity, nil, :model_classname => :MyEntity, :access_method => :ents, :inverse_access_method => :ent, :id_method => :key, :custom_initialize => true)

    assert_equal element.repository, repository
    assert_equal element.key, :entity
    assert_equal element.qualified_key, 'MyTypeSystem.entity'
    assert_equal element.container_key, nil
    assert_equal element.model_classname, :MyEntity
    assert_equal element.custom_initialize?, true
    assert_equal element.id_method, :key
    assert_equal element.access_method, :ents
    assert_equal element.inverse_access_method, :ent

    assert_equal repository.model_element_by_key?(:entity), true
  end

  def test_bad_attributes
    assert_model_error("Model Element 'MyTypeSystem.Entity' has a key 'Entity' that does not use the underscore naming pattern (i.e. The key should be 'entity').") do
      Reality::Model::ModelElement.new(Reality::Model::Repository.new(:MyTypeSystem, MyContainer), :Entity, nil, {})
    end
    assert_model_error("Model Element 'MyTypeSystem.entity' has a model_classname 'entity' that does not use the pascal case naming pattern (i.e. The model_classname should be 'Entity').") do
      Reality::Model::ModelElement.new(Reality::Model::Repository.new(:MyTypeSystem, MyContainer), :entity, nil, :model_classname => 'entity')
    end
    assert_model_error("Model Element 'MyTypeSystem.entity' has a access_method 'Entity' that does not use the underscore naming pattern (i.e. The access_method should be 'entity').") do
      Reality::Model::ModelElement.new(Reality::Model::Repository.new(:MyTypeSystem, MyContainer), :entity, nil, :access_method => 'Entity')
    end
    assert_model_error("Model Element 'MyTypeSystem.entity' has a inverse_access_method 'Entity' that does not use the underscore naming pattern (i.e. The inverse_access_method should be 'entity').") do
      Reality::Model::ModelElement.new(Reality::Model::Repository.new(:MyTypeSystem, MyContainer), :entity, nil, :inverse_access_method => 'Entity')
    end
    assert_model_error("Model Element 'MyTypeSystem.entity' has a id_method 'Name' that does not use the underscore naming pattern (i.e. The id_method should be 'name').") do
      Reality::Model::ModelElement.new(Reality::Model::Repository.new(:MyTypeSystem, MyContainer), :entity, nil, :id_method => 'Name')
    end
  end

  def test_bad_container_key
    assert_model_error("Model Element 'MyTypeSystem.component' defines container as 'bundle' but no such model element exists.") do
      Reality::Model::ModelElement.new(Reality::Model::Repository.new(:MyTypeSystem, MyContainer), :component, :bundle, {})
    end
  end

  def test_container_key
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer)
    element1 = Reality::Model::ModelElement.new(repository, :bundle, nil, {})
    element2 = Reality::Model::ModelElement.new(repository, :component, :bundle, {})

    assert_equal element1.key, :bundle
    assert_equal element1.container_key, nil
    assert_equal element2.key, :component
    assert_equal element2.container_key, :bundle

    assert_equal repository.model_element_by_key?(:bundle), true
    assert_equal repository.model_element_by_key?(:component), true
  end

  def test_build_child_accessor_code
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer)
    element1 = Reality::Model::ModelElement.new(repository, :bundle, nil, {})
    element2 = Reality::Model::ModelElement.new(repository, :component, :bundle, {})

    code = element1.send(:build_child_accessor_code, element2)
    assert_equal code, <<CODE

  public

  def component(name, options = {}, &block)
    Reality::Model::TestCase::MyContainer::Component.new(name, options, &block)
  end

  def component_by_name?(name)
    !!component_map[name.to_s]
  end

  def component_by_name(name)
    component = component_map[name.to_s]
    raise "No component with name '\#{name}' defined." unless component
    component
  end

  def components
    component_map.values
  end

  def components?
    !component_map.empty?
  end

  private

  def register_component(component)
    Reality::Model::TestCase::MyContainer.error("Attempting to register duplicate component definition with name '\#{name}'") if component_by_name?(component.name)
    component_map[component.name.to_s] = component
  end

  def component_map
    @component_map ||= Reality::OrderedHash.new
  end
CODE
  end

  def test_build_child_accessor_code_with_custom_initializer
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer)
    element1 = Reality::Model::ModelElement.new(repository, :bundle, nil, {})
    element2 = Reality::Model::ModelElement.new(repository, :component, :bundle, :custom_initialize => true)

    code = element1.send(:build_child_accessor_code, element2)
    assert_equal code, <<CODE

  public

  def component_by_name?(name)
    !!component_map[name.to_s]
  end

  def component_by_name(name)
    component = component_map[name.to_s]
    raise "No component with name '\#{name}' defined." unless component
    component
  end

  def components
    component_map.values
  end

  def components?
    !component_map.empty?
  end

  private

  def register_component(component)
    Reality::Model::TestCase::MyContainer.error("Attempting to register duplicate component definition with name '\#{name}'") if component_by_name?(component.name)
    component_map[component.name.to_s] = component
  end

  def component_map
    @component_map ||= Reality::OrderedHash.new
  end
CODE
  end

  def test_build_model_code
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer)
    element1 = Reality::Model::ModelElement.new(repository, :bundle, nil, {})

    code = element1.send(:build_model_code)
    assert_equal code, <<CODE
class Bundle
  attr_reader :name

  def initialize(name, options = {}, &block)
    @name = name
    Reality::Model::TestCase::MyContainer.info "Bundle '\#{name}' definition started."
    pre_init if respond_to?(:pre_init, true)
    self.options = options
    yield self if block_given?
    post_init if respond_to?(:post_init, true)
    Reality::Model::TestCase::MyContainer.info "Bundle '\#{name}' definition completed."
  end

  public

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
        raise "Attempted to configure property \\"\#{keys.last}\\" on Bundle but property does not exist."
      end
    end
  end
end
CODE
  end

  def test_build_model_code_for_contained_model
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer)
    Reality::Model::ModelElement.new(repository, :project, nil, {})
    element1 = Reality::Model::ModelElement.new(repository, :bundle, :project, {})

    code = element1.send(:build_model_code)
    assert_equal code, <<CODE
class Bundle
  attr_reader :name
  attr_reader :project

  def initialize(project, name, options = {}, &block)
    @name = name
    @project = project
    @project.send(:register_bundle, self)
    Reality::Model::TestCase::MyContainer.info "Bundle '\#{name}' definition started."
    pre_init if respond_to?(:pre_init, true)
    self.options = options
    yield self if block_given?
    post_init if respond_to?(:post_init, true)
    Reality::Model::TestCase::MyContainer.info "Bundle '\#{name}' definition completed."
  end

  public

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
        raise "Attempted to configure property \\"\#{keys.last}\\" on Bundle but property does not exist."
      end
    end
  end
end
CODE
  end

  def test_build_model_code_with_custom_initializer
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer)
    element1 = Reality::Model::ModelElement.new(repository, :bundle, nil, :custom_initialize => true)

    code = element1.send(:build_model_code)
    assert_equal code, <<CODE
class Bundle
  attr_reader :name

  def perform_init(name, options = {}, &block)
    @name = name
    Reality::Model::TestCase::MyContainer.info "Bundle '\#{name}' definition started."
    pre_init if respond_to?(:pre_init, true)
    self.options = options
    yield self if block_given?
    post_init if respond_to?(:post_init, true)
    Reality::Model::TestCase::MyContainer.info "Bundle '\#{name}' definition completed."
  end

  public

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
        raise "Attempted to configure property \\"\#{keys.last}\\" on Bundle but property does not exist."
      end
    end
  end
end
CODE
  end

  module MyFacetManager
  end

  def test_build_model_code_that_is_faceted
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer, :facet_container => MyFacetManager)
    element1 = Reality::Model::ModelElement.new(repository, :bundle, nil, {})

    code = element1.send(:build_model_code)
    assert_equal code, <<CODE
class Bundle
  attr_reader :name

  def initialize(name, options = {}, &block)
    @name = name
    Reality::Model::TestModelElement::MyFacetManager.target_manager.apply_extension(self)
    Reality::Model::TestCase::MyContainer.info "Bundle '\#{name}' definition started."
    pre_init if respond_to?(:pre_init, true)
    self.options = options
    yield self if block_given?
    post_init if respond_to?(:post_init, true)
    Reality::Model::TestCase::MyContainer.info "Bundle '\#{name}' definition completed."
  end

  public

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
        raise "Attempted to configure property \\"\#{keys.last}\\" on Bundle but property does not exist."
      end
    end
  end
end
CODE
  end

  def test_build_model_code_for_containing_model
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer)
    element0 = Reality::Model::ModelElement.new(repository, :project, nil, {})
    Reality::Model::ModelElement.new(repository, :bundle, :project, {})

    code = element0.send(:build_model_code)
    assert_equal code, <<CODE
class Project
  attr_reader :name

  def initialize(name, options = {}, &block)
    @name = name
    Reality::Model::TestCase::MyContainer.info "Project '\#{name}' definition started."
    pre_init if respond_to?(:pre_init, true)
    self.options = options
    yield self if block_given?
    post_init if respond_to?(:post_init, true)
    Reality::Model::TestCase::MyContainer.info "Project '\#{name}' definition completed."
  end

  public

  def bundle(name, options = {}, &block)
    Bundle.new(name, options, &block)
  end

  def bundle_by_name?(name)
    !!bundle_map[name.to_s]
  end

  def bundle_by_name(name)
    bundle = bundle_map[name.to_s]
    raise "No bundle with name '\#{name}' defined." unless bundle
    bundle
  end

  def bundles
    bundle_map.values
  end

  private

  def register_bundle(bundle)
    Reality::Model::TestCase::MyContainer.error("Attempting to register duplicate bundle definition with name '\#{name}'") if bundle_by_name?(bundle.name)
    bundle_map[bundle.name.to_s] = bundle
  end

  def bundle_map
    @bundle_map ||= Reality::OrderedHash.new
  end

  public

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
        raise "Attempted to configure property \\"\#{keys.last}\\" on Project but property does not exist."
      end
    end
  end
end
CODE
  end

  module ResgenContainer
  end

  def test_define_ruby_class
    repository = Reality::Model::Repository.new(:Resgen, ResgenContainer)
    model1 = Reality::Model::ModelElement.new(repository, :project, nil, {})
    model2 = Reality::Model::ModelElement.new(repository, :bundle, :project, {})

    assert_equal false, ResgenContainer.const_defined?(:Project)
    assert_equal false, ResgenContainer.const_defined?(:Bundle)

    model1.send(:define_ruby_class, ResgenContainer)

    assert_equal true, ResgenContainer.const_defined?(:Project)
    assert_equal false, ResgenContainer.const_defined?(:Bundle)

    model2.send(:define_ruby_class, ResgenContainer)

    assert_equal true, ResgenContainer.const_defined?(:Project)
    assert_equal true, ResgenContainer.const_defined?(:Bundle)

    assert_true ResgenContainer::Project.instance_methods.include?(:name)
    assert_true ResgenContainer::Project.instance_methods.include?(:bundles)
    assert_true ResgenContainer::Project.instance_methods.include?(:bundle_by_name)
    assert_true ResgenContainer::Project.instance_methods.include?(:bundle_by_name?)
    assert_true ResgenContainer::Project.instance_methods.include?(:bundle)
    assert_false ResgenContainer::Project.instance_methods.include?(:perform_init)

    assert_true ResgenContainer::Bundle.instance_methods.include?(:project)
    assert_true ResgenContainer::Bundle.instance_methods.include?(:name)
    assert_false ResgenContainer::Bundle.instance_methods.include?(:perform_init)
  end

  module ResgenContainer2
  end

  def test_define_ruby_class_with_heavy_customization
    repository = Reality::Model::Repository.new(:Resgen, ResgenContainer)
    model1 = Reality::Model::ModelElement.new(repository, :project, nil, :custom_initialize => true, :model_classname => :Prj, :inverse_access_method => :prj, :id_method => :key)
    model2 = Reality::Model::ModelElement.new(repository, :bundle, :project, :custom_initialize => true, :inverse_access_method => :bnd, :access_method => :bnds, :id_method => :key)

    assert_equal false, ResgenContainer2.const_defined?(:Prj)
    assert_equal false, ResgenContainer2.const_defined?(:Bundle)

    model1.send(:define_ruby_class, ResgenContainer2)

    assert_equal true, ResgenContainer2.const_defined?(:Prj)
    assert_equal false, ResgenContainer2.const_defined?(:Bundle)

    model2.send(:define_ruby_class, ResgenContainer2)

    assert_equal true, ResgenContainer2.const_defined?(:Prj)
    assert_equal true, ResgenContainer2.const_defined?(:Bundle)

    assert_equal ResgenContainer2::Prj, model1.model
    assert_equal ResgenContainer2::Bundle, model2.model

    assert_true ResgenContainer2::Prj.instance_methods.include?(:key)
    assert_false ResgenContainer2::Prj.instance_methods.include?(:name)
    assert_true ResgenContainer2::Prj.instance_methods.include?(:bnds)
    assert_true ResgenContainer2::Prj.instance_methods.include?(:bnd_by_key)
    assert_true ResgenContainer2::Prj.instance_methods.include?(:bnd_by_key?)

    # Need a custom initializer to be written
    assert_false ResgenContainer2::Prj.instance_methods.include?(:bundle)
    assert_false ResgenContainer2::Prj.instance_methods.include?(:bnd)

    assert_true ResgenContainer2::Bundle.instance_methods.include?(:prj)
    assert_true ResgenContainer2::Bundle.instance_methods.include?(:key)
    assert_false ResgenContainer2::Bundle.instance_methods.include?(:name)
  end
end
