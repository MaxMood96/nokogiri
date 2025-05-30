# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class Node
      class TestSaveOptions < Nokogiri::TestCase
        SaveOptions.constants.each do |constant|
          class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def test_predicate_#{constant.downcase}
              options = SaveOptions.new(SaveOptions::#{constant})
              assert options.#{constant.downcase}?

              assert SaveOptions.new.#{constant.downcase}.#{constant.downcase}?
            end
          RUBY
        end

        def test_default_xml_save_options
          if Nokogiri.jruby?
            assert_equal(0, SaveOptions::DEFAULT_XML & SaveOptions::FORMAT)
          else
            assert_equal(SaveOptions::FORMAT, SaveOptions::DEFAULT_XML & SaveOptions::FORMAT)
          end
        end
      end
    end
  end
end
