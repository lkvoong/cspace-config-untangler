require 'cspace_config_untangler'

module CspaceConfigUntangler
  module FieldMap
    class DataColumnNamerConsistent
      ::DataColumnNamerConsistent = CspaceConfigUntangler::FieldMap::DataColumnNamerConsistent
      attr_reader :result
      def initialize(fieldname:, sources:)
        @fieldname = fieldname
        @sources = sources
        @result = {}
        @sources.each do |source|
          name = "#{@fieldname}#{source.type.capitalize}#{source.subtype.capitalize}"
          @result[source.string] = name
        end
      end
    end
  end
end
