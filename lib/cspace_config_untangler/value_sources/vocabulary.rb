# frozen_string_literal: true

module CspaceConfigUntangler
  module ValueSources
    # basic value object to represent a vocabulary
    class Vocabulary
      attr_reader :name, :type, :subtype, :source_type
      def initialize(vocabulary_source_string)
        @type = 'vocabulary'
        @name = vocabulary_source_string
        @subtype = name
        @source_type = type
      end
    end
  end
end
