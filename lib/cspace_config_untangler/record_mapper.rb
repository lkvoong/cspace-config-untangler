require 'cspace_config_untangler'

module CspaceConfigUntangler
  module RecordMapper
    class RecordMapping
      ::RecordMapping = CspaceConfigUntangler::RecordMapper::RecordMapping
      attr_reader :hash

      # profile = string - name of profile
      # rectype = string - name of rectype to generate mapper for
      def initialize(profile:, rectype:)
        @profile = profile
        @rectype = rectype
        p = CCU::Profile.new(@profile, rectypes: [@rectype], structured_date_treatment: :collapse)
        @config = p.config
        @mappings = p.rectypes[0].fields.map{ |f| FieldMapper.new(field: f).mappings}.flatten
        @hash = {}
        build_hash
      end

      # output = string = path to output json file
      def to_json(output: "data/mappers/#{@profile}-#{@rectype}.json")
        File.open(output, 'w') do |f|
          f.puts JSON.pretty_generate(@hash)
        end
      end
      
      private

      def build_hash
        @hash[:config] = {}
        @hash[:config][:document_name] = @config.dig('recordTypes', @rectype, 'serviceConfig', 'documentName')
        @hash[:config][:service_name] = @config.dig('recordTypes', @rectype, 'serviceConfig', 'serviceName')
        @hash[:config][:service_path] = @config.dig('recordTypes', @rectype, 'serviceConfig', 'servicePath')
        @hash[:config][:service_type] = @config.dig('recordTypes', @rectype, 'serviceConfig', 'serviceType')
        @hash[:config][:object_name] = @config.dig('recordTypes', @rectype, 'serviceConfig', 'objectName')
        @hash[:config][:profile_basename] = @config.dig('basename').sub('/cspace/', '')
        @hash[:config][:ns_uri] = NamespaceUris.new(profile_config: @config,
                                                    rectype: @rectype,
                                                    mapper_config: @hash[:config]).hash
        @hash[:docstructure] = {}
        create_hierarchy
        @hash[:mappings] = @mappings.map{ |m| m.to_h }
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

      # def add_fieldmappings_holders
      #   @mappings.each do |m|
      #     path = m.xpath.clone
      #     path.prepend(m.namespace)
      #     to_update = @hash.dig(*path)
      #     if to_update
      #       to_update[:fieldmappings] = []
      #     else
      #       puts "Could not create holder for fieldmappings in #{m.namespace}/#{path.join('/')}"
      #     end
      #   end
      # end
      
      # def assign_mappings
      #   @mappings.each do |m|
      #     path = m.xpath.clone
      #     path.prepend(m.namespace)
      #     path << :fieldmappings
      #     to_update = @hash.dig(*path)
      #     to_update << m.to_h
      #   end
      # end
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
            if @mconfig[:service_type] == 'authority'
              objname = @mconfig[:service_path].sub(/authorit[y|ies]/, '')
            else
              objname = @mconfig[:object_name].downcase
            end
            
            if ns == "ns2:#{@mconfig[:document_name]}_common"
              uri = "http://collectionspace.org/services/#{objname}"
            elsif ns == "ns2:#{@mconfig[:document_name]}_#{@mconfig[:profile_basename]}"
              uri = "http://collectionspace.org/services/#{objname}/domain/#{@mconfig[:profile_basename]}"
            else
              ext = ns.sub("ns2:#{@mconfig[:document_name]}_", '').sub('_extension', '')
              uri = @config.dig('extensions', ext, objname, 'fields', ns, '[config]', 'service', 'ns')
            end
            @hash[ns] = uri
          end
      end
    end
  end
end #module
