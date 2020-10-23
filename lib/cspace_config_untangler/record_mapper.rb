require 'cspace_config_untangler'

module CspaceConfigUntangler
  module RecordMapper
    RecordMapper = CspaceConfigUntangler::RecordMapper

    class Validator
      attr_reader :path, :mapper, :valid, :errors, :validated
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

      def has_id_field
        id_field = @mapper.dig('config', 'identifier_field')
        if id_field.blank?
          @errors << 'No identifier field specified in config'
          return false
        else
          return true
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
    end
    
    class RecordMapping
      ::RecordMapping = CspaceConfigUntangler::RecordMapper::RecordMapping
      attr_reader :hash, :mappings

      # profile = CCU::Profile
      # rectype = CCU::RecordType
      def initialize(profile:, rectype:)
        @profile = profile
        @rectype = rectype
        @mappings = @rectype.batch_mappings
        @config = @profile.config
        @hash = {}
        build_hash
      end

      # output = string = path to output json file
      def to_json(output: "data/mappers/#{@profile.name}-#{@rectype.name}.json")
        File.open(output, 'w') do |f|
          f.write(JSON.pretty_generate(@hash))
        end
      end
      
      private

      def build_hash
        @hash[:config] = {}
        @hash[:config][:document_name] = @config.dig('recordTypes', @rectype.name, 'serviceConfig', 'documentName')
        @hash[:config][:service_name] = @config.dig('recordTypes', @rectype.name, 'serviceConfig', 'serviceName')
        @hash[:config][:service_path] = @config.dig('recordTypes', @rectype.name, 'serviceConfig', 'servicePath')
        @hash[:config][:service_type] = @config.dig('recordTypes', @rectype.name, 'serviceConfig', 'serviceType')
        @hash[:config][:object_name] = @config.dig('recordTypes', @rectype.name, 'serviceConfig', 'objectName')
        @hash[:config][:profile_basename] = @config.dig('basename').sub('/cspace/', '')
        @hash[:config][:ns_uri] = NamespaceUris.new(profile_config: @config,
                                                    rectype: @rectype.name,
                                                    mapper_config: @hash[:config]).hash
        @hash[:config][:identifier_field] = get_id_field
        @hash[:config][:authority_subtypes] = get_subtypes if @hash[:config][:service_type] == 'authority'
        @hash[:docstructure] = {}
        create_hierarchy
        @hash[:mappings] = @mappings.map{ |m| m.to_h }
      end

      def get_subtypes
        result = []
        vocabs = @config.dig('recordTypes', @rectype.name, 'vocabularies')
        vocabs.each do |keyword, config|
          next if keyword == 'all'
          name = config.dig('messages', 'name', 'defaultMessage')
          servicepath_name = config.dig('serviceConfig', 'servicePath').match(/\((.*)\)/)[1]
          result << { name: name, servicepath_name: servicepath_name }
        end
        result
      end

      def get_id_field
        case @hash[:config][:service_type]
        when 'object'
          id_field = 'objectNumber'
        when 'authority'
          id_field = 'shortIdentifier'
        when 'procedure'
          mapping = @mappings.select{ |m| m.required == 'y' }
          if mapping.length == 1
            id_field = mapping.first.fieldname
          elsif mapping.length > 1
            # osteology has 3 required fields, but only the ID is suitable for use here
            id_field = 'InventoryID' if @rectype.name == 'osteology'
            id_field = 'movementReferenceNumber' if @rectype.name == 'movement' && !@profile.name.start_with?('botgarden')
          end
        end
        id_field
      end
      
      def create_hierarchy
        # top level keys are the namespaces
        @mappings.each do |m|
          @hash[:docstructure][m.namespace] = {}
        end

        @mappings.each do |m|
          levels = m.xpath.clone
          done = []
          while levels.size > 0 do
            thislevel = levels.shift
            path = done.clone << thislevel
            add_key = @hash[:docstructure][m.namespace].dig(*path) ? false : true
            if add_key
              add_path = done.empty? ? @hash[:docstructure][m.namespace] : @hash[:docstructure][m.namespace].dig(*done)
              add_path[thislevel] = {}
            end
            done << thislevel
          end
        end
      end
    end #class RecordMapper

    # returns hash of namespaces in a document, and their namespace URIs
    # profile_config = Hash from CCU::Profile.config
    # rectype = String
    # mapper_config = Hash of mapper
    class NamespaceUris
      ::NamespaceUris = CspaceConfigUntangler::RecordMapper::NamespaceUris
      attr_reader :hash
      def initialize(profile_config:, rectype:, mapper_config:)
        @config = profile_config
        @rectype = rectype
        @mconfig = mapper_config
        @hash = {}
        @config.dig('recordTypes', @rectype, 'fields', 'document').keys
          .select{ |k| k.start_with?('ns2') }
          .reject{ |k| k == 'ns2:collectionspace_core' || k == 'ns2:account_permission' }
          .each do |ns|
            objname = @mconfig[:object_name].downcase unless @mconfig[:service_type] == 'authority'
            if ns == "ns2:#{@mconfig[:document_name]}_common"
              if @mconfig[:service_type] == 'authority'
                uri = @config.dig('recordTypes', @rectype, 'fields', 'document', ns, 'csid', '[config]',
                                  'extensionParentConfig', 'service', 'ns')
              else
                uri = "http://collectionspace.org/services/#{objname}"
              end
            elsif ns == "ns2:#{@mconfig[:document_name]}_#{@mconfig[:profile_basename]}"
              uri = "http://collectionspace.org/services/#{objname}/domain/#{@mconfig[:profile_basename]}"
            else
              ext = ns.sub("ns2:#{@mconfig[:document_name]}_", '').sub('_extension', '')
              uri = @config.dig('extensions', ext, objname, 'fields', ns, '[config]', 'service', 'ns')
            end
            @hash[ns.sub('ns2:', '')] = uri
          end
      end
    end
  end
end #module
