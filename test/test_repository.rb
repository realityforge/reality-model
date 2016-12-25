require File.expand_path('../helper', __FILE__)

class Reality::Model::TestRepository < Reality::Model::TestCase
  def test_basic_operation
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer)

    assert_equal repository.key, :MyTypeSystem
    assert_equal repository.model_container, MyContainer
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

  module MyLogContainer
  end

  module MyFacetContainer
  end

  def test_create_no_defaults
    repository = Reality::Model::Repository.new(:MyTypeSystem,
                                                MyContainer,
                                                :log_container => MyLogContainer,
                                                :facet_container => MyFacetContainer)

    assert_equal repository.key, :MyTypeSystem
    assert_equal repository.model_container, MyContainer
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

    repository.lock!

    assert_equal repository.locked?, true

    assert_model_error("Attempting to define model element 'Domgen.view' when repository is locked.") do
      repository.model_element(:view, :entity)
    end

    assert_model_error("Attempting to lock repository 'Domgen' when repository is already locked.") do
      repository.lock!
    end
  end
end
