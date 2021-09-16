# frozen_string_literal: true

module CspaceConfigUntangler
  module ValueSources
    # basic value object to represent an authority
    class Authority
      attr_reader :name, :type, :subtype, :source_type
      def initialize(authority_source_string)
        @name = authority_source_string
        split = name.split('/')
        @type = split[0]
        @subtype = split[1]
        @source_type = 'authority'
      end
    end
  end
end
