require File.expand_path('../helper', __FILE__)

class Reality::Model::TestRepository < Reality::Model::TestCase
  def test_basic_operation
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer)

    assert_equal repository.key, :MyTypeSystem
    assert_equal repository.model_container, MyContainer
    assert_equal repository.instance_container, MyContainer
    assert_equal repository.log_container, MyContainer
    assert_equal repository.facet_container, nil
    assert_equal repository.faceted?, false
    assert_equal repository.model_element_keys, []
    assert_equal repository.model_elements, []
    assert_equal repository.model_elements_by_container(:entity), []

    assert_equal repository.model_element_by_key?(:entity), false

    assert_model_error("Can not find model element 'entity' in repository 'MyTypeSystem'.") do
      repository.model_element_by_key(:entity)
    end

    element = repository.model_element(:entity)

    assert_equal repository.model_element_by_key?(:entity), true
    assert_equal repository.model_element_keys, ['entity']
    assert_equal repository.model_elements, [element]
    assert_equal repository.model_elements_by_container(:entity), []
  end

  def test_validate_options
    assert_model_error("Unknown option ':x' passed to create repository") do
      Reality::Model::Repository.new(:MyTypeSystem, MyContainer, :x => 1)
    end

    assert_model_error('Unknown options [:x, :z] passed to create repository') do
      Reality::Model::Repository.new(:MyTypeSystem, MyContainer, :x => 1, :z => 1)
    end
  end

  module MyLogContainer
  end

  module MyFacetContainer
  end

  module MyInstanceContainer
  end

  def test_create_no_defaults
    repository = Reality::Model::Repository.new(:MyTypeSystem,
                                                MyContainer,
                                                :instance_container => MyInstanceContainer,
                                                :log_container => MyLogContainer,
                                                :facet_container => MyFacetContainer)

    assert_equal repository.key, :MyTypeSystem
    assert_equal repository.model_container, MyContainer
    assert_equal repository.instance_container, MyInstanceContainer
    assert_equal repository.log_container, MyLogContainer
    assert_equal repository.facet_container, MyFacetContainer
    assert_equal repository.faceted?, true
  end

  def test_yield
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer) do |repo|
      repo.model_element(:entity)
    end

    assert_equal repository.locked?, true

    assert_equal repository.key, :MyTypeSystem
    assert_equal repository.model_element_by_key?(:entity), true
  end

  def test_register_duplicates
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer)

    repository.model_element(:entity)

    assert_equal repository.model_element_by_key?(:entity), true

    assert_model_error("Attempting to redefine model element 'MyTypeSystem.entity'") do
      repository.model_element(:entity)
    end
  end

  def test_model_elements_by_container
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer)

    repository.model_element(:entity)

    assert_equal repository.model_elements_by_container(:entity), []

    element2 = repository.model_element(:attribute, :entity)
    element3 = repository.model_element(:view, :entity)

    assert_equal repository.model_elements_by_container(:entity), [element2, element3]
  end

  def test_lock
    repository = Reality::Model::Repository.new(:Domgen, MyContainer)

    assert_equal repository.locked?, false

    repository.model_element(:entity)
    repository.model_element(:attribute, :entity)

    assert_equal repository.model_elements.size, 2

    assert_equal false, MyContainer.const_defined?(:Entity)
    assert_equal false, MyContainer.const_defined?(:Attribute)

    repository.lock!

    assert_equal true, MyContainer.const_defined?(:Entity)
    assert_equal true, MyContainer.const_defined?(:Attribute)

    assert_equal repository.locked?, true

    assert_model_error("Attempting to define model element 'Domgen.view' when repository is locked.") do
      repository.model_element(:view, :entity)
    end

    assert_model_error("Attempting to lock repository 'Domgen' when repository is already locked.") do
      repository.lock!
    end
  end

  def test_define_ruby_classes
    repository = Reality::Model::Repository.new(:Resgen, MyContainer)
    Reality::Model::ModelElement.new(repository, :project, nil, {})
    Reality::Model::ModelElement.new(repository, :bundle, :project, {})

    assert_equal false, MyContainer.const_defined?(:Project)
    assert_equal false, MyContainer.const_defined?(:Bundle)

    repository.send(:define_ruby_classes)

    assert_equal true, MyContainer.const_defined?(:Project)
    assert_equal true, MyContainer.const_defined?(:Bundle)
  end

  module MyInstanceContainer2
  end

  def test_lock_called_if_block_supplied_to_constructor
    assert_equal false, MyContainer.const_defined?(:Project)
    assert_equal false, MyContainer.const_defined?(:Bundle)

    repository = Reality::Model::Repository.new(:Resgen, MyContainer, :instance_container => MyInstanceContainer2) do |r|
      r.model_element(:project)
      r.model_element(:bundle, :project)
    end

    assert_equal true, repository.locked?

    assert_equal true, MyContainer.const_defined?(:Project)
    assert_equal true, MyContainer.const_defined?(:Bundle)

    assert_true MyInstanceContainer2.public_methods.include?(:projects)
    assert_true MyInstanceContainer2.public_methods.include?(:project_by_name)
    assert_true MyInstanceContainer2.public_methods.include?(:project_by_name?)
    assert_true MyInstanceContainer2.public_methods.include?(:project)
  end

  module MyInstanceContainer3
  end

  def test_define_top_level_instance_accessors

    assert_false MyInstanceContainer3.public_methods.include?(:projects)
    assert_false MyInstanceContainer3.public_methods.include?(:project_by_name)
    assert_false MyInstanceContainer3.public_methods.include?(:project_by_name?)
    assert_false MyInstanceContainer3.public_methods.include?(:project)

    repository = Reality::Model::Repository.new(:Resgen, MyContainer, :instance_container => MyInstanceContainer3)
    Reality::Model::ModelElement.new(repository, :project, nil, {})

    repository.send(:define_top_level_instance_accessors)

    assert_true MyInstanceContainer3.public_methods.include?(:projects)
    assert_true MyInstanceContainer3.public_methods.include?(:project_by_name)
    assert_true MyInstanceContainer3.public_methods.include?(:project_by_name?)
    assert_true MyInstanceContainer3.public_methods.include?(:project)
  end

  module MyFacetManager
    extend Reality::Facets::FacetContainer
  end

  def test_define_facet_targets
    assert_equal MyFacetManager.target_manager.target_keys, []

    Reality::Model::Repository.new(:Resgen, MyContainer, :facet_container => MyFacetManager) do |r|
      r.model_element(:project)
      r.model_element(:bundle, :project, :inverse_access_method => :bnd, :access_method => :bnds)
      r.model_element(:image, :bundle)
    end

    assert_equal MyFacetManager.target_manager.target_keys, [:project, :bundle, :image]

    target1 = MyFacetManager.target_manager.target_by_key(:project)
    target2 = MyFacetManager.target_manager.target_by_key(:bundle)
    target3 = MyFacetManager.target_manager.target_by_key(:image)

    assert_equal :project, target1.inverse_access_method
    assert_equal :projects, target1.access_method
    assert_equal nil, target1.container_key
    assert_equal :project, target1.key
    assert_equal Reality::Model::TestCase::MyContainer::Project, target1.model_class

    assert_equal :bnd, target2.inverse_access_method
    assert_equal :bnds, target2.access_method
    assert_equal :project, target2.container_key
    assert_equal :bundle, target2.key
    assert_equal Reality::Model::TestCase::MyContainer::Bundle, target2.model_class

    assert_equal :image, target3.inverse_access_method
    assert_equal :images, target3.access_method
    assert_equal :bundle, target3.container_key
    assert_equal :image, target3.key
    assert_equal Reality::Model::TestCase::MyContainer::Image, target3.model_class
  end
end
