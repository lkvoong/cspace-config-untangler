require 'cspace_config_untangler'

module CspaceConfigUntangler
  module FieldMap
    class FieldMapping
      ::FieldMapping = CspaceConfigUntangler::FieldMap::FieldMapping
      include CCU::TrackAttributes
      attr_reader :fieldname, :datacolumn, :transforms, :source_type, :namespace, :xpath, :data_type,
        :required, :repeats, :in_repeating_group, :opt_list_values
      def initialize(field:, datacolumn:, transforms: {}, source_type:)
        @fieldname = field.name
        @namespace = field.ns.sub('ns2:', '')
        @xpath = field.schema_path
        @required = field.required
        @repeats = field.repeats
        @in_repeating_group = field.in_repeating_group
        @data_type = field.data_type
        @datacolumn = datacolumn
        @source_type = source_type
        @transforms = transforms
        @opt_list_values = field.value_list
      end

      def to_h
        attrs = self.attr_readers
        ivs = attrs.map{ |e| '@' + e.to_s }.map{ |e| e.to_sym }
        h = {}
        attrs.each_with_index{ |a, i| h[a.to_sym] = self.instance_variable_get(ivs[i]) }
        return h
      end
    end

    # given a CSpace field, will generate one or more FieldMapping objects (which relate to incoming data key/columns)
    class FieldMapper
      ::FieldMapper = CspaceConfigUntangler::FieldMap::FieldMapper
      attr_reader :mappings, :hash, :source_type
      def initialize(field:)
        @field = field
        @hash = structure_hash
        get_data_columns
        get_source_type
        get_transforms
        @mappings = create_mappings
        @field = @field.name
      end

      private

      def structure_hash
        h = {}
        sources = @field.value_source.empty? ? ['no source'] : @field.value_source
        sources.each do |vs|
          h[vs] = { column_name: '',
                   transforms: {},
                   source_type: ''}
        end
        h
      end
      
      def get_source_type
        types = []
        @hash.each do |source, h|
          if source.start_with?('authority: ')
            h[:source_type] = 'authority'
          elsif source.start_with?('vocabulary: ')
            h[:source_type] = 'vocabulary'
          elsif source.start_with?('option list: ')
            h[:source_type] = 'optionlist'
          else
            h[:source_type] = 'na'
          end
        types << h[:source_type]
        end
        @source_type = types[0]
      end
      
      def get_transforms
        @hash.each do |source, h|
          xform = { special: []}
          if source.start_with?('authority: ')
            xform[:authority] = AuthorityConfigLookup.new(profile: @field.profile,
                                                           authority: source).result
          elsif source.start_with?('vocabulary: ')
            xform[:vocabulary] = source.sub('vocabulary: ', '')
            xform[:special] << 'behrensmeyer_translate' if @field.name.downcase['behrensmeyer']
          elsif @field.data_type == 'boolean'
            xform[:special] << 'boolean'
          end

          xform.delete(:special) if xform[:special].empty?
          
          h[:transforms] = h[:transforms].merge(xform)
        end
      end
      
      def create_mappings
        mappings = []
        @hash.each do |source, h|
          mappings << FieldMapping.new(field: @field,
                                       datacolumn: h[:column_name],
                                       transforms: h[:transforms],
                                       source_type: h[:source_type])
        end
        mappings
      end
      
      def get_data_columns
        value_source = @field.value_source
        if value_source.empty?
          @hash['no source'] = { column_name: @field.name, transforms: {} }
        elsif value_source.size == 1
          value_source.each{ |vs| @hash[vs] = { column_name: @field.name, transforms: {} } }
        else #multiple sources
          DataColumnNamer.new(fieldname: @field.name, sources: value_source).result.each do |src, colname|
            @hash[src][:column_name] = colname
          end
        end
      end
    end #class FieldMapper

    class AuthorityConfigLookup
      ::AuthorityConfigLookup = CspaceConfigUntangler::FieldMap::AuthorityConfigLookup
      attr_reader :result
      def initialize(profile:, authority:)
        source = authority.sub('authority: ', '').split('/')
        authtype = source[0]
        authsubtype = source[1]
        path = profile.config.dig('recordTypes', authtype, 'serviceConfig', 'servicePath')
        subpath = profile.config.dig('recordTypes', authtype, 'vocabularies', authsubtype,
                                    'serviceConfig', 'servicePath')
        subpath = subpath.match(/\((.*)\)$/)[1]
        @result = [path, subpath]
      end
    end

    class DataColumnNamer
      ::DataColumnNamer = CspaceConfigUntangler::FieldMap::DataColumnNamer
      attr_reader :result
      def initialize(fieldname:, sources:)
        @fieldname = fieldname
        @sources = sources
        @result = {}

        # build hash used to check whether to name using authority type, subtype, or both
        srcs = @sources.map{ |s| s.sub('authority: ', '') }
          .map{ |s| s.split('/') }
        h = {}
        srcs.each{ |s| h[s[0]] = [] }
        srcs.each{ |s| h[s[0]] << s[1]}
        
        @sources.each do |s|
          name = @fieldname.clone
          ssplit = s.sub('authority: ', '').split('/')
          use_type = h.keys.size > 1 ? true : false
          use_subtype = h[ssplit[0]].size > 1 ? true : false
          name = use_type ? name << ssplit[0].capitalize : name
          name = use_subtype ? name << ssplit[1].capitalize : name
          @result[s] = name
        end
      end
    end
  end
end
