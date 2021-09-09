# frozen_string_literal: true

require_relative 'field_definition'

module CspaceConfigUntangler
  module Fields
    module Definition
      # ensures some fields do not get included in the resulting field definitions
      class FieldFilter
        # list of fields to omit from resulting field definitions
        OmittedFields = %w[csid inAuthority refName shortIdentifier]

        # @param config [CCU::Fields::Definition::Config]
        def self.call(config)
          return if OmittedFields.any?(config.name)

          field_def = FieldDefintion.new(config)
          return unless field_def
          
          update_field_defs(config, field_def)
        end

        private

        def update_field_defs(config, field_def)
          config.parser.add_field_def(field_def)
        end
      end
    end
  end
end
