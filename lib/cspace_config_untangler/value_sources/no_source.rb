# frozen_string_literal: true

module CspaceConfigUntangler
  module ValueSources
    # nil value object representing no value source
    class NoSource
      attr_reader :name, :type, :subtype, :source_type
      # @param source [CCU::ValueSources::Authority, CCU::ValueSources::Vocabulary]
      def initialize
        @type = 'na'
        @source_type = type
        @name = type
        @subtype = type
      end
    end
  end
end
