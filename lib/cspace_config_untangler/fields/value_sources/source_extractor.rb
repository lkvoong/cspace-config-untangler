# frozen_string_literal: true

module CspaceConfigUntangler
  module Fields
    module ValueSources
      class SourceExtractor
        # Authority sources where there is no config to inform mappings
        IgnoredAuthorities = [
          'citation/shared',
          'concept/material_shared',
          'organization/shared',
          'person/shared',
          'place/shared'
          ]
        def self.call(type, field_hash, option_lists)
          return [CCU::ValueSources::NoSource.new] if type == 'no source'
          
          sources = field_hash.dig('view', 'props', 'source')

          case type
          when 'option list'
            [option_lists.get_option_list(sources)]
          when 'vocabulary'
            [CCU::ValueSources::Vocabulary.new(sources)]
          when 'authority'
            sources.split(',')
              .reject{ |source| IgnoredAuthorities.any?(source) }
              .map{ |source| CCU::ValueSources::Authority.new(source) }
          end
        end
      end
    end
  end
end

