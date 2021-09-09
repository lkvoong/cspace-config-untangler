# frozen_string_literal: true

module CspaceConfigUntangler
  # basic value object to represent an authority
  class Authority
    attr_reader :name, :type, :subtype
    def initialize(authority_source_string)
      @name = authority_source_string
      split = name.split('/')
      @type = split[0]
      @subtype = split[1]
    end
  end
end
