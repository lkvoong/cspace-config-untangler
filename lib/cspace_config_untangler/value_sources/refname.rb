# frozen_string_literal: true

module CspaceConfigUntangler
  module ValueSources
    # Authority or Vocabulary Refname source
    class Refname
      attr_reader :name, :type, :subtype, :source_type
      # @param source [CCU::ValueSources::Authority, CCU::ValueSources::Vocabulary]
      def initialize(source)
        @type = source.source_type
        @source_type = 'refname'
        @name = "#{type} #{source_type}"
        @subtype = nil
      end
    end
  end
end
