require_relative 'track_attributes'

module CspaceConfigUntangler
  module FieldMap
    class FieldMapping
      ::FieldMapping = CspaceConfigUntangler::FieldMap::FieldMapping
      include CCU::TrackAttributes
      attr_reader :fieldname, :transforms, :source_type, :source_name, :namespace, :xpath, :data_type,
        :repeats, :in_repeating_group, :opt_list_values
      attr_accessor :datacolumn, :required
      def initialize(field:, datacolumn:, transforms: {}, source_type:, source_name:)
        @fieldname = field.name
        @namespace = field.ns.sub('ns2:', '')
        @xpath = field.schema_path
        @required = field.required ? field.required : 'n'
        @repeats = field.repeats
        @in_repeating_group = field.in_repeating_group ? field.in_repeating_group : 'n'
        @datacolumn = datacolumn
        @source_type = source_type
        @source_name = source_name
        @transforms = transforms
        @opt_list_values = field.value_list
        @data_type = @datacolumn['Refname'] ? 'csrefname' : field.data_type
      end

      def to_h
        readable = self.attr_readers
        accessible = self.attr_accessors
        attrs = readable + accessible
        
        ivs = attrs.flatten.map{ |e| '@' + e.to_s }.map{ |e| e.to_sym }
        h = {}
        attrs.each_with_index{ |a, i| h[a.to_sym] = self.instance_variable_get(ivs[i]) }
        return h
      end
    end

    # given a CSpace field, will generate one or more FieldMapping objects (which relate to incoming data key/columns)
    class FieldMapper
      ::FieldMapper = CspaceConfigUntangler::FieldMap::FieldMapper
      attr_reader :mappings, :hash, :source_type
      def initialize(field:, column_style: :consistent)
        @field = field
        @column_style = column_style
        @hash = structure_hash
        get_data_columns
        get_source_types
        get_transforms
        @mappings = create_mappings
      end

      private

      def structure_hash
        result = {}
        sources = @field.value_source.blank? ? [CCU::ValueSources::NoSource.new] : @field.value_source
        sources.each do |source|
          result[source] = { column_name: '',
                   transforms: {},
                   source_type: ''}
        end
        result
      end
      
      def get_source_types
        types = []
        @hash.each do |source, h|
          type = get_source_type(source)
          types << type
          h[:source_type] = type
        end
        @source_type = types[0]
      end

      def get_source_type(source)
        binding.pry if source.is_a?(String)
        source.source_type
      end

      def get_source_type_transforms(source, xform)
        return xform if source == 'no source'
        
        case source.source_type
        when 'authority'
          xform[:authority] = source.service_paths
        when 'vocabulary'
          xform[:vocabulary] = source.subtype
        end
      end
      
      def get_transforms
        @hash.each do |source, h|
          next if source.source_type == 'refname'
          
          xform = { special: []}

          get_source_type_transforms(source, xform)
          
          xform[:special] << 'behrensmeyer_translate' if @field.name.downcase['behrensmeyer']
          xform[:special] << 'boolean' if @field.data_type == 'boolean'
          xform.delete(:special) if xform[:special].empty?
          
          h[:transforms] = h[:transforms].merge(xform)
        end
      end
      
      def create_mappings
        mappings = []
        @hash.each do |source, h|
          next if source.source_type == 'authority' && !source.configured?
          
          mappings << FieldMapping.new(field: @field,
                                       datacolumn: h[:column_name],
                                       transforms: h[:transforms],
                                       source_type: h[:source_type],
                                       source_name: h[:source_name])
        end
        mappings
      end
      
      def get_data_columns
        value_source = @field.value_source
        
        if value_source.blank?
          @hash['no source'] = { column_name: @field.name, transforms: {} }
          return
        end
        
        if value_source.size == 1
          vs = value_source.first
          source_name = get_source_name(vs)
          @hash[vs] = { column_name: @field.name, transforms: {}, source_name: source_name }

        else #multiple sources
          namer_opts = {fieldname: @field.name, sources: transform_sources(value_source)}
          namer = @column_style == :fancy ? DataColumnNamerFancy.new(**namer_opts) : DataColumnNamerConsistent.new(**namer_opts)
          namer.result.each do |src, colname|
            @hash[src][:column_name] = colname
            @hash[src][:transforms] = {}
            @hash[src][:source_name] = get_source_name(src)
          end
        end

        add_refname_source_column(value_source.first) if needs_refname_source?(value_source.first)
      end

      def add_refname_source_column(source)
        refname_src = CCU::ValueSources::Refname.new(source)
        col = { column_name: "#{@field.name}Refname", transforms: {}, source_name: source.name }
        @hash[refname_src] = col
      end

      # @param source [#source_type]
      def needs_refname_source?(source)
        refname_req = %w[authority vocabulary]
        refname_req.any?(source.source_type)
      end
      
      def transform_sources(sources)
        sources
      end

      def get_source_name(source)
        source.name
        # if source.is_a?(AuthoritySource)
        #   source.string
        # else
        #   source.sub(/^(option list|authority|vocabulary): /, '')
        # end
      end
    end #class FieldMapper

    class AuthoritySource
      ::AuthoritySource = CspaceConfigUntangler::FieldMap::AuthoritySource
      attr_reader :type, :subtype, :string

      def initialize(value_source)
        @string = value_source
        split = value_source.sub('authority: ', '').split('/')
        @type = split[0]
        @subtype = split[1]
      end
    end
  end
end
