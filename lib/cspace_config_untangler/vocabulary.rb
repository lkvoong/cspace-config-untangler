# frozen_string_literal: true

module CspaceConfigUntangler
  # basic value object to represent a vocabulary
  class Vocabulary
    attr_reader :name, :type, :subtype
    def initialize(vocabulary_source_string)
      @name = vocabulary_source_string
      @type = 'vocabulary'
      @subtype = name
    end
  end
end
