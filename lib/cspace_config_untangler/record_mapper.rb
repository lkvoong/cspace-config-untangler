require 'cspace_config_untangler'

module CspaceConfigUntangler
    class RecordMapper
      ::RecordMapper = CspaceConfigUntangler::RecordMapper
      attr_reader :hash, :mappings

      # profile = string - name of profile
      # rectype = string - name of rectype to generate mapper for
      def initialize(profile:, rectype:)
        @profile = profile
        @rectype = rectype
        p = CCU::Profile.new(@profile, rectypes: [@rectype], structured_date_treatment: :collapse)
        @mappings = p.rectypes[0].fields.map{ |f| FieldMapper.new(field: f).mappings}.flatten
        @hash = {}
        get_mapping
      end

      # output = string = path to output json file
      def to_json(output: "data/mappers/#{@profile}-#{@rectype}.json")
        File.open(output, 'w') do |f|
          f.puts JSON.pretty_generate(@hash)
        end
      end
      
      private

      def get_mapping
        # top level keys are the namespaces
        @mappings.each do |m|
          @hash[m.namespace] = {}
        end
        create_hierarchy
        add_fieldmappings_holders
        assign_mappings
      end

      def create_hierarchy
        @mappings.each do |m|
          levels = m.xpath.clone
          done = []
          while levels.size > 0 do
            thislevel = levels.shift
            path = done.clone << thislevel
            add_key = @hash[m.namespace].dig(*path) ? false : true
            if add_key
              add_path = done.empty? ? @hash[m.namespace] : @hash[m.namespace].dig(*done)
              add_path[thislevel] = {}
            end
            done << thislevel
          end
        end
      end

      def add_fieldmappings_holders
        @mappings.each do |m|
          path = m.xpath.clone
          path.prepend(m.namespace)
          to_update = @hash.dig(*path)
          if to_update
            to_update[:fieldmappings] = []
          else
            puts "Could not create holder for fieldmappings in #{m.namespace}/#{path.join('/')}"
          end
        end
      end
      
      def assign_mappings
        @mappings.each do |m|
          path = m.xpath.clone
          path.prepend(m.namespace)
          path << :fieldmappings
          to_update = @hash.dig(*path)
          to_update << m.to_h
        end
      end
    end #class RecordMapper
end #module
