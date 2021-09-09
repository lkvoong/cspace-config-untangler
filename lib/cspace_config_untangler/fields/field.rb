require 'cspace_config_untangler'

module CspaceConfigUntangler
  module Fields
    class Field
      attr_reader :name, :ns, :ns_for_id, :panel, :ui_path, :id,
        :schema_path,
        :repeats, :in_repeating_group,
        :data_type, :value_source, :value_list,
        :required
      attr_accessor :to_csv, :profile, :rectype

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

      # returns copy of this Field object without all the profile and rectype data
      def clean
        c = self.dup
        c.profile = @profile.name
        c.rectype = @rectype.name
        c
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
        fd = @profile.field_defs.dig(@id)
        if fd.nil?
          return find_field_def_alt
        elsif fd.length == 1
          return fd.first
        else
          return fd.select{ |f| f.ns == @ns }.first
        end
      end

      def find_field_def_alt
        if @ns == 'ns2:conservation_livingplant'
          try_id = @id.sub('ext.', 'conservation_')
        else
          try_id = "#{@ns.sub('ns2:', '')}.#{@name}"
        end
        
        fd = @profile.field_defs.dig(try_id)
        if fd.nil?
          return nil
        elsif fd.length == 1
          return fd.first
        else
          return fd.select{ |f| f.ns == @ns }.first
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
    end #class Field
    
    # Provides a way to force a field external to the configs into Untangler output
    # Initially used only to make CSV templates for Media record types include a mediaFileURI field
    # See the `media_uri_field` private method in record_types.rb for how to set up field_hash parameter.
    class ForcedField < Field
      def initialize(rectype_obj, field_hash)
        @rectype = rectype_obj
        @profile = @rectype.profile
        @name = field_hash[:name]
        @ns = field_hash[:ns]
        @ns_for_id = @ns
        @panel = ''
        @ui_path = []
        @id = "#{@ns}.#{@name}"
        @schema_path = []
        @repeats = field_hash[:repeats]
        @in_repeating_group = field_hash[:in_repeating_group]
        @data_type = field_hash[:data_type]
        @value_source = field_hash[:value_source]
        @value_list = field_hash[:value_list]
        @required = field_hash[:required]
        @to_csv = format_csv
      end
    end
  end
end
