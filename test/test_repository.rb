require File.expand_path('../helper', __FILE__)

class Reality::Model::TestRepository < Reality::Model::TestCase
  def test_basic_operation
    repository = Reality::Model::Repository.new(:MyTypeSystem)

    assert_equal repository.key, :MyTypeSystem
    assert_equal repository.model_element_keys, []
    assert_equal repository.model_elements, []
    assert_equal repository.model_elements_by_container(:entity), []

    assert_equal repository.model_element_by_key?(:entity), false

    assert_raise(RuntimeError.new("Can not find model element 'entity' in repository 'MyTypeSystem'")) do
      repository.model_element_by_key(:entity)
    end

    element = repository.model_element(:entity)

    assert_equal repository.model_element_by_key?(:entity), true
    assert_equal repository.model_element_keys, ['entity']
    assert_equal repository.model_elements, [element]
    assert_equal repository.model_elements_by_container(:entity), []
  end

  def test_register_duplicates
    repository = Reality::Model::Repository.new(:MyTypeSystem)

    repository.model_element(:entity)

    assert_equal repository.model_element_by_key?(:entity), true

    assert_raise(RuntimeError.new("Attempting to redefine model element 'MyTypeSystem.entity'")) do
      repository.model_element(:entity)
    end
  end

  def test_model_elements_by_container
    repository = Reality::Model::Repository.new(:MyTypeSystem)

    repository.model_element(:entity)

    assert_equal repository.model_elements_by_container(:entity), []

    element2 = repository.model_element(:attribute, :entity)
    element3 = repository.model_element(:view, :entity)

    assert_equal repository.model_elements_by_container(:entity), [element2, element3]
  end
end
