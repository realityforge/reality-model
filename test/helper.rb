$:.unshift File.expand_path('../../lib', __FILE__)

require 'minitest/autorun'
require 'test/unit/assertions'
require 'reality/model'
require 'reality/facets'

class Reality::Model::TestCase < Minitest::Test
  include Test::Unit::Assertions
  include Reality::Logging::Assertions

  def setup
    Reality::Model::TestCase.send(:remove_const, :MyContainer) if Reality::Model::TestCase.const_defined?(:MyContainer)
    Reality::Model::TestCase.module_eval <<-RUBY
      module MyContainer
      end
    RUBY
  end

  def assert_model_error(expected_message, &block)
    assert_logging_error(Reality::Model, expected_message) do
      yield block
    end
  end
end
