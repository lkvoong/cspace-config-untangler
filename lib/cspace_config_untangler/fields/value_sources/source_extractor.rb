# frozen_string_literal: true

module CspaceConfigUntangler
  module Fields
    module ValueSources
      class SourceExtractor
        def self.call(type, field_hash)
          sources = field_hash.dig('view', 'props', 'source')
          return unless sources

          
        end
      end
    end
  end
end

