require 'cspace_config_untangler'

module CspaceConfigUntangler
  
  class StructuredDateField < Field
  attr_reader :profile, :rectype, :name, :ns, :ns_for_id, :panel, :ui_path, :id,
      :schema_path,
      :repeats, :in_repeating_group,
      :data_type, :value_source, :value_list,
      :required,
      :to_csv

    def initialize(profile_obj, structured_date_field_maker, field_id)
      @parent = structured_date_field_maker
      @profile = profile_obj
      @rectype = @parent.rectype
      @name = field_id.sub('ext.structuredDate.', '')
      @ns = @parent.ns
      @ns_for_id = @parent.ns_for_id
      @panel = @parent.panel
      @ui_path = @parent.ui_path
      @id = field_id
      @schema_path = @parent.schema_path
      @repeats = @parent.repeats
      @in_repeating_group = @parent.in_repeating_group
      @required = @parent.required
      @data_type = set_data_type(@name)
      @value_source = []
      @value_list = []
      
      @to_csv = format_csv
    end

    private

    def set_data_type(fieldname)
      h = {
        'dateDisplayDate' => 'string',
        'dateAssociation' => 'string',
        'datePeriod' => 'string',
        'dateNote' => 'string',
        'dateEarliestSingleCertainty' => 'string',
        'dateEarliestSingleDay' => 'integer',
        'dateEarliestSingleEra' => 'string',
        'dateEarliestSingleMonth' => 'integer',
        'dateEarliestSingleQualifier' => 'string',
        'dateEarliestSingleQualifierUnit' => 'string',
        'dateEarliestSingleQualifierValue' => 'integer',
        'dateEarliestSingleYear' => 'integer',
        'dateLatestCertainty' => 'string',
        'dateLatestDay' => 'integer',
        'dateLatestEra' => 'string',
        'dateLatestMonth' => 'integer',
        'dateLatestQualifier' => 'string',
        'dateLatestQualifierUnit' => 'string',
        'dateLatestQualifierValue' => 'integer',
        'dateLatestYear' => 'integer',
        'dateEarliestScalarValue' => 'string',
        'dateLatestScalarValue' => 'string',
        'scalarValuesComputed' => 'boolean'
      }
      return h[fieldname]
    end
    
  end #class Field
  
  
end #module
