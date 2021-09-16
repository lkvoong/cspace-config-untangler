# frozen_string_literal: true

require_relative 'reportable'

module CspaceConfigUntangler
  module ValueSources
    # basic value object to represent an option list
    class OptionList
      include CCU::ValueSources::Reportable
      attr_reader :name, :source_type, :options
      def initialize(name, list_config)
        @name = name
        @options = list_config['values'].sort
        @source_type = 'optionlist'
      end
    end
  end
end
