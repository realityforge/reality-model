require File.expand_path('../helper', __FILE__)

class Reality::Model::TestModelElement < Reality::Model::TestCase
  def test_basic_operation
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer)
    element = Reality::Model::ModelElement.new(repository, :entity, nil, {})

    assert_equal element.repository, repository
    assert_equal element.key, :entity
    assert_equal element.container_key, nil
    assert_equal element.model_classname, :Entity
    assert_equal element.id_method, :name
    assert_equal element.access_method, :entities
    assert_equal element.inverse_access_method, :entity

    assert_equal repository.model_element_by_key?(:entity), true
  end

  def test_default_value_of_id_method
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer, :id_method => :key)
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
      assert_equal element.id_method, :name
      assert_equal element.access_method, :entities
      assert_equal element.inverse_access_method, :entity

      assert_equal repository.model_element_by_key?(:entity), true
    end
  end

  def test_basic_operation_with_no_defaults
    repository = Reality::Model::Repository.new(:MyTypeSystem, MyContainer)
    element = Reality::Model::ModelElement.new(repository, :entity, nil, :model_classname => :MyEntity, :access_method => :ents, :inverse_access_method => :ent, :id_method => :key)

    assert_equal element.repository, repository
    assert_equal element.key, :entity
    assert_equal element.qualified_key, 'MyTypeSystem.entity'
    assert_equal element.container_key, nil
    assert_equal element.model_classname, :MyEntity
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
end
