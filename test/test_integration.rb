require File.expand_path('../helper', __FILE__)

class Reality::Model::TestIntegration < Reality::Model::TestCase

  module ResgenLogContainer
    Reality::Logging.configure(ResgenLogContainer, ::Logger::WARN)
  end

  module ResgenFacetContainer
    extend Reality::Facets::FacetContainer
  end

  module ResgenInstanceContainer
  end

  module ResgenModel
    class Repository
      def catalog(name, path, options = {}, &block)
        Catalog.new(self, name, path, options, &block)
      end
    end

    class Catalog
      def initialize(repository, name, path, options = {}, &block)
        @path = path
        perform_init(repository, name, options, &block)
      end

      attr_reader :path
    end
  end

  def test_create_no_defaults
    Reality::Model::Repository.new(:Resgen,
                                   ResgenModel,
                                   :instance_container => ResgenInstanceContainer,
                                   :facet_container => ResgenFacetContainer,
                                   :log_container => ResgenLogContainer) do |r|
      r.model_element(:repository)
      r.model_element(:catalog, :repository, :custom_initialize => true)
      r.model_element(:uibinder_file, :catalog, :id_method => :key)
      r.model_element(:uibinder_parameter, :uibinder_file, :access_method => :parameters, :inverse_access_method => :parameter)
    end

    ResgenFacetContainer.facet(:gwt) do |facet|
      facet.enhance(ResgenModel::Catalog) do
        attr_writer :with_lookup

        def with_lookup?
          !!(@with_lookup ||= false)
        end
      end
    end

    assert_equal ResgenInstanceContainer.repository_names, []
    assert_equal ResgenInstanceContainer.repositories, []

    repository = ResgenInstanceContainer.repository(:Planner) do |r|
      r.enable_facets(:gwt)
      r.catalog(:PlannerCatalog, 'user-experience/src/main/resources', 'gwt.with_lookup' => true) do |c|
        c.uibinder_file(:SomeCell1) do |u|
          u.parameter(:ParamB)
          u.parameter(:ParamA)
          u.parameter(:ParamC)
        end
        c.uibinder_file(:SomeCell2) do |u|
          u.parameter(:ParamB)
          u.parameter(:ParamA)
          u.parameter(:ParamC)
        end
      end
    end

    assert_equal ResgenInstanceContainer.repository_names, ['Planner']
    assert_equal ResgenInstanceContainer.repositories, [repository]
    assert_equal ResgenInstanceContainer.repository_by_name(:Planner), repository

    assert_equal repository.gwt?, true
    assert_equal repository.respond_to?(:gwt), false

    assert_equal repository.catalog_names, ['PlannerCatalog']
    assert_equal repository.catalogs.size, 1
    assert_equal repository.catalog_by_name?('PlannerCatalog'), true

    catalog = repository.catalog_by_name('PlannerCatalog')

    assert_equal catalog.gwt?, true
    assert_equal catalog.respond_to?(:gwt), true
    assert_equal catalog.gwt.with_lookup?, true

    assert_equal catalog.repository, repository
    assert_equal catalog.path, 'user-experience/src/main/resources'

    assert_equal catalog.uibinder_file_keys, %w(SomeCell1 SomeCell2)
    assert_equal catalog.uibinder_files.size, 2
    assert_equal catalog.uibinder_file_by_key?('SomeCell1'), true

    uibinder_file = catalog.uibinder_file_by_key('SomeCell1')

    assert_equal uibinder_file.catalog, catalog
    assert_equal uibinder_file.parameter_names, %w(ParamB ParamA ParamC)
    assert_equal uibinder_file.parameters.size, 3
    assert_equal uibinder_file.parameter_by_name?('ParamA'), true

    assert_equal uibinder_file.parameters.collect { |p| p.name }, [:ParamB, :ParamA, :ParamC]
    assert_equal uibinder_file.parameters.sort.collect { |p| p.name }, [:ParamA, :ParamB, :ParamC]

    parameter = uibinder_file.parameter_by_name('ParamA')

    assert_equal parameter.uibinder_file, uibinder_file
  end
end
