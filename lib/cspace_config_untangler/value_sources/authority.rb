# frozen_string_literal: true

require_relative 'reportable'

module CspaceConfigUntangler
  module ValueSources
    # basic value object to represent an authority
    class Authority
      include CCU::ValueSources::Reportable
      attr_reader :name, :type, :subtype, :source_type
      def initialize(authority_source_string, profile)
        @name = authority_source_string
        split = name.split('/')
        @type = split[0]
        @subtype = split[1]
        @source_type = 'authority'
        @config = profile.config.dig('recordTypes', type)
      end

      def configured?
        service_paths.length == 2
      end

      def service_paths
        return [] unless @config
        
        [type_service_path, subtype_service_path].compact
      end

      private

      def type_service_path
        path = @config.dig('serviceConfig', 'servicePath')
        return unless path

        path
      end

      def subtype_service_path
        subtype_config = @config.dig('vocabularies', subtype)
        return unless subtype_config
        
        path = subtype_config.dig('serviceConfig', 'servicePath')
        return unless path

        path.match(/\((.*)\)$/)[1]
      end
    end
  end
end
