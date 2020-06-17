require 'cspace_config_untangler'

module CspaceConfigUntangler
  module FieldMap
    class FieldMapping
      include CCU::TrackAttributes
      attr_reader :fieldname, :datacolumn, :transforms, :sourcetype, :namespace, :xpath, :data_type, :required
      def initialize(field:, datacolumn:, transforms: {}, sourcetype:)
        @fieldname = field.name
        @namespace = field.ns
        @xpath = field.schema_path
        @required = field.required
        @data_type = field.data_type
        @datacolumn = datacolumn
        @sourcetype = sourcetype
        @transforms = transforms
      end

            def to_h
        attrs = self.attr_readers.map{ |e| '@' + e.to_s }.map{ |e| e.to_sym }
        h = {}
        attrs.each{ |a| h[a] = self.instance_variable_get(a) }
        return h
            end
    end
    
    class FieldMapper
      ::FieldMapper = CspaceConfigUntangler::FieldMap::FieldMapper
      attr_reader :mappings, :hash, :source_type
      def initialize(field:)
        @field = field
        @hash = structure_hash
        get_data_columns
        @source_type = get_source_type
        get_transforms
        @mappings = create_mappings
      end

      private

      def structure_hash
        h = {}
        sources = @field.value_source.empty? ? ['no source'] : @field.value_source
        sources.each do |vs|
          h[vs] = { column_name: '',
                   transforms: {},
                   sourcetype: '' }
        end
        h
      end
      
      def get_source_type
        types = []
        @hash.each do |source, h|
          if source.start_with?('authority: ')
            types << 'authority'
          elsif source.start_with?('vocabulary: ')
            types << 'vocabulary'
          elsif source.start_with?('option list: ')
            types << 'optionlist'
          else
            types << 'na'
          end
        end
        types[0]
      end
      
      def get_transforms
        @hash.each do |source, h|
          xform = {}
          if source.start_with?('authority: ')
            xform['authority'] = AuthorityConfigLookup.new(profile: @field.profile,
                                                           authority: source).result
          elsif source.start_with?('vocabulary: ')
            xform['vocab'] = source.sub('vocabulary: ', '')
          elsif @field.data_type == 'structured date group'
            xform['special'] = 'structured_date'
          elsif @field.data_type == 'boolean'
            xform['special'] = 'boolean'
          end
          h[:transforms] = h[:transforms].merge(xform)
        end
      end
      
      def create_mappings
        mappings = []
        @hash.each do |source, h|
          mappings << FieldMapping.new(field: @field,
                                       datacolumn: h[:column_name],
                                       transforms: h[:transforms],
                                       sourcetype: h[:source_type])
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
