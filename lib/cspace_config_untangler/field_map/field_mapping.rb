require_relative '../track_attributes'

module CspaceConfigUntangler
  module FieldMap
    # Represents mapping instructions for data from a specific value source for a given field
    #
    # If the field has no refname-requiring value sources (i.e. authority or vocabulary sources),
    #   there is a 1-to-1 correspondence between fields and FieldMappings
    #
    # If the field is populated from a vocabulary or from one or more authorities, a FieldMapping is
    #   created for of those sources. An additional "refname" FieldMapping is added to support batch ingest using
    #   CS refnames instead of authority terms.
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
  end
end
