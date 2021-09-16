require 'cspace_config_untangler'

module CspaceConfigUntangler
  module RecordMapper
    RecordMapper = CspaceConfigUntangler::RecordMapper

    class Validator
      attr_reader :path, :valid, :errors, :validated
      def initialize(path)
        @path = path
        @valid = false
        @validated = false
        @errors = []
        begin
          @mapper = JSON.parse(File.read(@path))
        rescue JSON::ParserError
          @errors <<  "#{@path} is not a valid JSON file"
          @mapper = nil
        end
      end

      def validate
        @validated = true
        return if @mapper.nil?
        results = [
          main_keys_present,
          has_profile_basename,
          has_recordtype,
          has_version,
          has_ns_uris,
          has_id_field,
          has_field_mapping_namespaces,
          term_source_types_ok
        ]
        @valid = true if results.uniq == [true]
      end

      def report
        validate unless @validated
        unless @valid
          puts ''
          puts "INVALID: #{@path}"
          @errors.uniq.each{ |err| puts "  #{err}" }
          puts ''
        end
      end

      private

      def main_keys_present
        expected = %w[config docstructure mappings]
        keys = @mapper.keys
        diff = expected - keys
        if diff.empty?
          true
        else
          diff.each{ |key| @errors << "Missing top-level key: #{key}" }
          false
        end
      end

      def has_profile_basename
        if @mapper['config']['profile_basename'].blank?
          @errors << 'Profile lacks config/profile_basename'
          false
        else
          true
        end
      end
      
      def has_recordtype
        if @mapper['config']['recordtype'].blank?
          @errors << 'Profile lacks config/recordtype'
          false
        else
          true
        end
      end
      
      def has_version
        if @mapper['config']['version'].blank?
          @errors << 'Profile lacks config/version'
          false
        else
          true
        end
      end
      
      def has_ns_uris
        ns_hash = @mapper.dig('config', 'ns_uri')
        if ns_hash.nil?
          @errors << 'No namespace hash in config'
          return false
        end

        null_uris = ns_hash.select{ |ns, uri| uri.nil? }
        if null_uris.empty?
          return true
        else
          null_uris.keys.each{ |ns| @errors << "No namespace URI extracted for #{ns}" }
          return false
        end
      end

      def has_id_field
        id_field = @mapper.dig('config', 'identifier_field')
        if id_field.blank?
          @errors << 'No identifier field specified in config'
          return false
        else
          return true
        end
      end

      def has_field_mapping_namespaces
        mappings = @mapper.dig('mappings')
        if mappings.blank?
          @errors << 'No field mappings specified'
          return false
        end

        missing_ns = mappings.select{ |mapping| mapping['namespace'].blank? }
        if missing_ns.empty?
          return true
        else
          missing_ns.each{ |mapping| @errors << "Field mapping(s) for #{mapping['fieldname']} lack(s) namespace" }
          return false
        end
      end

      def term_source_types_ok
        mappings = @mapper.dig('mappings')
        if mappings.blank?
          @errors << 'No field mappings specified'
          return false
        end
        not_ok = mappings.select{ |mapping| mapping['source_type'].start_with?('invalid source type') }
        if not_ok.empty?
          return true
        else
          not_ok.each{ |mapping| @errors << "Source type for #{mapping['fieldname']} is not an option_list, vocabulary, or authority." }
          return false
        end
      end
    end

    class RecordMapperWrapper
      ::RecordMapperWrapper = CspaceConfigUntangler::RecordMapper::RecordMapperWrapper

      attr_reader :mappers
      def initialize(profile:, rectype:, base_path:)
        @profile = profile
        @rectype = rectype
        @base_path = base_path
        @service_type = @rectype.service_type
        @mappers = []

        if @service_type == 'authority'
          @rectype.subtypes.each do |subtype|
            @mappers << get_wrapped_mapper(subtype: subtype)
          end
        else
          @mappers << get_wrapped_mapper
        end
      end

      private

      def get_wrapped_mapper(subtype: nil)
        if subtype
          {
            mapper: RecordMapping.new(profile: @profile, rectype: @rectype, subtype: subtype),
            path: "#{@base_path}/#{@profile.name}_#{@rectype.name}-#{subtype[:name].downcase.gsub(' ', '-')}.json"
          }
        else
          {
            mapper: RecordMapping.new(profile: @profile, rectype: @rectype),
            path: "#{@base_path}/#{@profile.name}_#{@rectype.name}.json"
          }
        end
      end
    end
    


    # returns hash of namespaces in a document, and their namespace URIs
    # profile_config = Hash from CCU::Profile.config
    # rectype = String
    # mapper_config = Hash of mapper
    class NamespaceUris
      ::NamespaceUris = CspaceConfigUntangler::RecordMapper::NamespaceUris

      WEIRD_NS_LOOKUP = {
        'ns2:collectionobjects_annotation' => 'http://collectionspace.org/services/collectionobject/domain/annotation',
        'ns2:groups_checklist'=> 'http://collectionspace.org/services/group/domain/checklist',
        'ns2:collectionobjects_variablemedia' => 'http://collectionspace.org/services/collectionobject/domain/collectionobject',
        'ns2:collectionobjects_fineart' => 'http://collectionspace.org/services/collectionobject/domain/collectionobject',
        'ns2:concepts_fineart' => 'http://collectionspace.org/services/concept/domain/fineart',
        'ns2:conditionchecks_variablemedia' => 'http://collectionspace.org/services/conditioncheck/domain/variablemedia',
        'ns2:acquisitions_commission' => 'http://collectionspace.org/services/acquisition/domain/commission',
        'ns2:propagations_common' => 'http://collectionspace.org/services/propagation',
        'ns2:osteology_anthropology' => 'http://collectionspace.org/services/osteology/domain/anthropology'
      }
      def initialize(profile_config:, rectype:, mapper_config:)
        @config = profile_config
        @rectype = rectype
        @mconfig = mapper_config
      end

      def hash
        hash = {}
        @config.dig('recordTypes', @rectype, 'fields', 'document').keys
          .select{ |k| k.start_with?('ns2') }
          .reject{ |k| k == 'ns2:collectionspace_core' || k == 'ns2:account_permission' }
          .each{ |ns| hash[ns.sub('ns2:', '')] = uri(ns) }
        hash
      end

      private

      def authority_ns_uri(ns)
        @config.dig('recordTypes', @rectype, 'fields', 'document', ns, 'csid', '[config]',
                    'extensionParentConfig', 'service', 'ns')
      end

      def extension_ns_uri(ns)
        ext = ns.sub("ns2:#{@mconfig[:document_name]}_", '').sub('_extension', '')
        @config.dig('extensions', ext, object_name, 'fields', ns, '[config]', 'service', 'ns')
      end

      def object_name
        @mconfig[:object_name].downcase unless @mconfig[:service_type] == 'authority'
      end

      def uri(ns)
        case ns
        when 'ns2:contacts_common'
          "http://collectionspace.org/services/contact"
        when "ns2:#{@mconfig[:document_name]}_common"
          if @mconfig[:service_type] == 'authority'
            authority_ns_uri(ns)
          else
            "http://collectionspace.org/services/#{object_name}"
          end
        when "ns2:#{@mconfig[:document_name]}_#{@mconfig[:profile_basename]}"
          "http://collectionspace.org/services/#{object_name}/domain/#{@mconfig[:profile_basename]}"
        else
          WEIRD_NS_LOOKUP.keys.include?(ns) ? WEIRD_NS_LOOKUP[ns] : extension_ns_uri(ns)
        end
      end
    end
  end
end #module
