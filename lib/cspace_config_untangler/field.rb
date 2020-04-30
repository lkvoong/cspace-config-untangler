require 'cspace_config_untangler'

module CspaceConfigUntangler
  
  class Field
  attr_reader :profile, :rectype, :name, :ns, :ns_for_id, :panel, :ui_path, :id,
      :schema_path,
      :repeats, :in_repeating_group,
      :data_type, :value_source, :value_list,
      :required,
      :to_csv

    def initialize(rectype_obj, form_field)
      ff = form_field
      @rectype = rectype_obj
      @profile = @rectype.profile
      @name = ff.name
      @ns = ff.ns
      @ns_for_id = ff.ns_for_id
      @panel = ff.panel
      @ui_path = ff.ui_path
      @id = ff.id
      merge_field_defs
      @to_csv = format_csv
      clean_up
    end

    def csv_header
      return %w[profile record_type namespace namespace_for_id field_id ui_info_group ui_path ui_field_label xml_path xml_field_name data_type required repeats group_repeats data_source option_list_values]
    end

    def structured_date?
      if @data_type == 'structured date group'
        return true
      else
        return false
      end
    end

    private
    
    def format_csv
      arr = [@profile.name]
      @rectype.is_a?(CCU::RecordType) ? arr << @rectype.name : arr << @rectype
      @ns ? arr << @ns : arr << ''
      @ns_for_id ? arr << @ns_for_id : arr << ''
      @id ? arr << @id : arr << ''
      if @ui_path
        path = @ui_path.compact
        path = path.map{ |e| lookup_display_name(e) }
        arr << path.shift
        arr << path.compact.join(' > ')
      else
        arr << ''
        arr << ''
      end
      @id ? arr << lookup_display_name(@id) : arr << ''
      @schema_path ? arr << @schema_path.join(' > ') : arr << ''
      @name ? arr << @name : arr << ''
      @data_type ? arr << @data_type : arr << ''
      @required ? arr << @required : arr << ''
      @repeats ? arr << @repeats : arr << ''
      @in_repeating_group ? arr << @in_repeating_group : arr << ''
      @value_source ? arr << @value_source.join('; ') : arr << ''
      @value_list ? arr << @value_list.join(', ') : arr << ''
      return arr
    end

    def merge_field_defs
      fd = find_field_def
      merge_from_fd(fd) if fd
    end

    def find_field_def
      if @profile.field_defs[:single].has_key?(@id)
        return @profile.field_defs[:single][@id]
      elsif @profile.field_defs[:multi].has_key?(@id)
        set = @profile.field_defs[:multi][@id]
        return set.select{ |e| e.ns == @ns }.first
      else
        return find_field_def_alt
      end
    end

    def find_field_def_alt
      if @ns == 'ns2:conservation_livingplant'
        try_id = @id.sub('ext.', 'conservation_')
      end

      if @profile.field_defs[:single].has_key?(try_id)
        return @profile.field_defs[:single][try_id]
      elsif @profile.field_defs[:multi].has_key?(try_id)
        set = @profile.field_defs[:multi][try_id]
        return set.select{ |e| e.ns == @ns }.first
      else
        return nil
      end
    end

    def merge_from_fd(fd)
      @schema_path = fd.schema_path
      @repeats = fd.repeats
      @in_repeating_group = fd.in_repeating_group
      @data_type = fd.data_type
      @value_source = fd.value_source
      @value_list = fd.value_list
      @required = fd.required
    end
    
    def lookup_display_name(val)
      msgs = @profile.messages
      if val.start_with?('panel.')
        if msgs.dig(val, 'name')
          new = msgs[val]['name']
        else
          new = alt_panel_lookup(val)
        end
      elsif val.start_with?('inputTable.')
        msgs.dig(val, 'name') ? new = msgs[val]['name'] : new = val
      else
        val = "field.#{val}"
        if msgs.dig(val, 'fullName')
          new = msgs[val]['fullName']
        elsif msgs.dig(val, 'name')
          new = msgs[val]['name']
        elsif val.end_with?('Group')
          new = nil
        elsif val.end_with?('List')
          new = nil
        elsif val.end_with?('s')
          new = nil
        else
          new = val
        end
      end
      return new
    end

    def alt_panel_lookup(val)
      trunc_lookup = {}
      @profile.messages.select{ |id, h| id.start_with?('panel.') }.each{ |id, h|
        name = id.split('.').last
        trunc_lookup[name] = h
      }
      trunc_val = val.split('.').last
      
      if trunc_lookup.dig(trunc_val, 'name')
        new = trunc_lookup[trunc_val]['name']
      else
        new = val
      end
      return new
    end

    def clean_up
      @profile = @profile.name
      @rectype = @rectype.name
    end
    
  end #class Field
  
  
end #module
