require 'cspace_config_untangler'

module CspaceConfigUntangler
  module FieldMap
    class FieldMapping
      attr_reader :fieldname, :datacolumn, :transforms, :namespace, :xpath, :required
      def initialize(fieldname:, datacolumn:, transforms: [])
        @fieldname = fieldname
        @datacolumn = datacolumn
        @transforms = transforms
      end
    end
    
    class FieldMapper
      ::FieldMapper = CspaceConfigUntangler::FieldMap::FieldMapper
      attr_reader :mappings, :columns
      def initialize(field:)
        @field = field
        @hash = {}
        @mappings = []
        get_data_columns(@field.value_source)
        @columns = @hash.map{ |source, h| h[:column_name] }
        create_mappings
      end

      private

      def create_mappings
        @hash.each do |source, h|
          @mappings << FieldMapping.new(fieldname: @field.name,
                                        datacolumn: h[:column_name],
                                        transforms: h[:transforms])
        end
      end
      
      def get_data_columns(value_source)
        if value_source.empty?
          @hash['no source'] = { column_name: @field.name,
                                transforms: []
                               }
        elsif value_source.size == 1
          value_source.each do |vs|
            @hash[vs] = { column_name: @field.name,
                         transforms: []}
            # todo: set transforms for this source
          end
        else #multiple sources
          @hash = @hash.merge(DataColumnNamer.new(fieldname: @field.name, sources: value_source).result)
        end
      end

      def get_transforms
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
         @result[s] = { transforms: [] }
         name = @fieldname.clone
         ssplit = s.sub('authority: ', '').split('/')
         use_type = h.keys.size > 1 ? true : false
         use_subtype = h[ssplit[0]].size > 1 ? true : false
         name = use_type ? name << ssplit[0].capitalize : name
         name = use_subtype ? name << ssplit[1].capitalize : name
         @result[s][:column_name] = name
        end
      end
    end
  end
end
