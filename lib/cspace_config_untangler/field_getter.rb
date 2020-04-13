require 'cspace_config_untangler'

module CspaceConfigUntangler
  class FieldData
    attr_accessor :hash
    
    def initialize(ns)
      @hash = {ns: ns,
               field_source: nil,
               schemapath: [],
               schemafield: '',
               fulllabel: nil,
               label: '',
               inrepeatinggroup: nil,
               repeats: nil,
               repeat_type: '',
               datatype: nil,
               field_value_sources: [],
               field_value_list: [],
               required: nil,
               warn: []
              }
    end
  end
  
  # extracts field info from a config
  class FieldGetter
    attr_reader :profile
    attr_reader :rectype
    attr_reader :rto # CCU::RecordType object
    attr_reader :config
    attr_reader :fields
    attr_reader :option_lists
    attr_reader :option_list_config
    attr_reader :vocabularies
    
    def initialize(profile, rectype)
      @profile = profile
      @rectype = rectype
      @rto = CCU::RecordType.new(@profile, @rectype)
      @config = @rto.config
      opt_lists = CCU::ProfileOptionLists.new(@profile)
      @option_lists = opt_lists.list
      @option_list_config = opt_lists.config
      @vocabularies = CCU::ProfileVocabularies.new(@profile).list
      @fields = {}
    end

    def empty?
      return true if @fields.empty?
      return false
    end
  end

  # pull field definition data from:
  #  CCU::Profile.config['recordTypes'][rectype]['fields']['document']
  class FieldDefinitionGetter < FieldGetter
    attr_reader :authorities
    
    def initialize(profile, rectype)
      super
      @authorities = CCU::ProfileAuthorities.new(profile).list
      extract_fields
      drop_unused_fields
      #f = @fields.select{ |field, hash| hash[:warn].length > 0 }
      #f.each{ |field, hash| puts "#{field} -- #{hash[:warn]}" }
      #      pp(@fields)
      # bring to your attention datatypes that need to be set up!
      # @fields.each{ |field, data|
      #   puts "#{field} -- #{data[:datatype]}" if data[:datatype].include?('TODO')
      # }
      pp(@fields)
      return @fields
    end

    private

    # some fields may be defined in core or an extension that is used, but not included in any
    #  form definitions, meaning they are effectively NOT included in a profile.
    #  This method removes these fields from the field list. 
    def drop_unused_fields
      form_fields = CCU::FormFieldGetter.new(@profile, @rectype).list
      def_fields = @fields.keys
      def_fields.each{ |df|
        if @fields[df][:ns] == @fields[df][:field_source]
          unless form_fields.include?("/#{@fields[df][:schemafield]}")
            LOG.info("#{profile} - #{rectype} defines field #{@fields[df][:schemafield]}, but it is not used in any forms")
            @fields.delete(df)
          end
        end
      }
    end

    def extract_fields
      fhash = @config['fields']['document']
      fhash.keys.each{ |ns|
        case ns
        when '[config]'
          # skip
        when 'ns2:collectionspace_core'
          # skip
        when 'rel:relations-common-list'
          # todo: process relation fields
        else
          process_ns(ns, fhash[ns])
        end
      }
    end

    def process_ns(ns, hash)
      ns = ns.sub('ns2:', '')
      bindle = CCU::FieldData.new(ns).hash
      
      hash.each{ | key, data|
        unless key == '[config]'
          if is_group?(data)
            grp_bindle = CCU::safe_copy(bindle)
            grp_bindle[:schemapath] << key
            process_field_group(grp_bindle, key, data)
          else
            process_field_data(CCU::safe_copy(bindle), key, data['[config]'])
          end
        end
      }
    end

    def process_field_group(bindle, parent_field, data)
      bindle[:inrepeatinggroup] = data.dig('[config]', 'repeating') ? true : nil

      data.keys.reject{ |e| e == '[config]' }.each{ |key|
        if is_group?(data[key])
          fge_bindle = CCU::safe_copy(bindle)
          fge_bindle[:schemapath] << key
          process_field_group(fge_bindle, key, data[key])
        else	
          process_field_data(CCU::safe_copy(bindle), key, data[key]['[config]'])
        end
      }
    end

    
    def process_field_data(bindle, fieldname, config)
      path = bindle[:schemapath].join(':')
      fieldkey = bindle[:ns]
      fieldkey += ":#{path}" unless bindle[:schemapath].empty?
      fieldkey += ":#{fieldname}"
      bindle[:schemafield] = fieldname
      bindle[:fulllabel] = config.dig('messages', 'fullName', 'defaultMessage')
      bindle[:label] = config.dig('messages', 'name', 'defaultMessage')
      bindle[:repeats] = true if config['repeating'] && config['repeating'] == true
      bindle[:datatype] = get_datatype(config['dataType'])

      if config.dig('extensionName')
        source = config['extensionName']
      elsif config.dig('messages', 'name', 'id') && config['messages']['name']['id'].match?(/field\.ext\.([^.]+)\./)
        source = config['messages']['name']['id'].match(/field\.ext\.([^.]+)\./)[1]
      else
        source = bindle[:ns]
      end
      bindle[:field_source] = source

      set_repeatability(bindle)

      get_sources(bindle, config.dig('view', 'props'))

      @fields[fieldkey.to_sym] = bindle
    end

    def set_repeatability(bindle)
      group = bindle[:inrepeatinggroup]
      field = bindle[:repeats]

      if group == true && field == true
        bindle[:repeat_type] = 'repeatable value in repeatable group'
      elsif group == true
        bindle[:repeat_type] = 'non-repeatable value in repeatable group'
      elsif field == true && bindle[:schemapath].length > 0
        bindle[:repeat_type] = 'repeatable value in non-repeatable group'
      else
        bindle[:repeat_type] = 'non-repeatable value, not in group'
      end
    end

    def get_datatype(val)
      val = val.sub('DATA_TYPE_', '') if val
      case val
      when nil
        return 'string'
      when 'INT'
        return 'integer'
      when 'FLOAT'
        return 'float'
      when 'BOOL'
        return 'boolean'
      when 'DATE'
        return 'date'
      else
        return "TODO: convert: #{val}"
      end
    end
    
    def is_group?(hash)
      case hash.keys
      when ['[config]']
        return false
      else
        return true
      end
    end

    def get_sources(bindle, data)
      return bindle if data.nil?

      if data.has_key?('autoComplete') && !data.has_key?('source')
        bindle[:warn] << 'Autocomplete defined with no source'
        return bindle
      end

      if data.has_key?('source')
        sources = data['source'].split(',')
        sources.each{ |source|
          if @option_lists.include?(source)
            bindle[:field_value_sources] << "option list: #{source}"
            @option_list_config[source]['values'].each{ |val| bindle[:field_value_list] << val }
          elsif @authorities.include?(source)
            bindle[:field_value_sources] << "authority: #{source}"
          elsif @vocabularies.include?(source)
            bindle[:field_value_sources] << "vocabulary: #{source}"
          elsif source['/']
            # do nothing; authority not included in this profile is specified in field definition
            #  reused by multiple profiles
          elsif %[accession intake loanin].include?(source)
            # do nothing; defines number pattern or object/procedure linkage
          else
            bindle[:warn] << "Source value '#{source}' is not an option list, authority, or vocabulary"
            bindle[:field_value_sources] << "other: #{source}"
          end
        }
      end

      [:field_value_sources, :field_value_list].each{ |key|
        bindle[key].flatten!
        bindle[key].uniq!
        bindle[key].sort!
      }

      return bindle
    end
  end

  
  # We are getting a path hierarchy from the form data, but this is NOT the path that
  #  controls the nesting of XML fields. It's just for info's sake here. 
  class FormFieldGetter < FieldGetter
    attr_reader :forms
    attr_reader :panel_names
    
    def initialize(profile, rectype)
      super
      get_panel_names
      
      if has_forms?
        set_forms
        @forms.each{ |form| extract_fields(form) }
      end
      return @fields
    end

    def list
      list = []
      @fields.each{ |namespace, fieldhash|
        fieldhash.each{ |fieldname, datahash|
          datahash[@profile][@rectype].each{ |formname, formfield|
              f = formfield['path'].match(/.*(\/[A-Za-z\-]+)$/)[1]
              list << f
          }
        }
      }
      list.uniq!
      return list
    end
    
    private

    def get_panel_names
      @panel_names = []
      if @config.dig('messages', 'panel')
        @config['messages']['panel'].keys.each{ |k| @panel_names << k }
      end

      exts = CCU::ProfileExtensions.new(@profile).config
      
      exts.each{ |ext, data|
        if data.dig(@rectype, 'messages', 'inputTable')
          data[@rectype]['messages']['inputTable'].keys.each{ |k| @panel_names << k }
        end
      }
    end
    
    def has_forms?
      return true if @config.has_key?('forms')
      return false
    end

    def set_forms
      @forms = @config['forms'].keys.reject{ |form| @config['forms'][form].has_key?('disabled') }
    end

    def extract_fields(form)
      # form template contains 'props' hash
      template = @config['forms'][form]['template']
      # props hash has keys: name, children. name = document
      # the children are the top level sections of the forms
      sections = template['props']['children']
      # sections is an Array if there is more than one top level section in the form
      # sections is a Hash if there is only one section in the form. We wrap these in an Array
      #   to make processing of sections consistent.
      sections = [sections] if sections.is_a?(Hash)
      sections.each{ |section| process_section(form, section) }
    end

    def process_section(form, section)
      # Every section is a hash with the following keys:
      #  key ref props _owner
      # anthro claim default form also has a section with key type => 'div' that can be ignored
      # the only thing informative here is props
      props = section['props']
      # props is a Hash
      # All but anthro claim default have a 'name' key. It only has 'children'.
      # We'll return an empty string for that one.
      section_name = props.keys.include?('name') ? props['name'] : ''

      # Some sections do not have children. Return them as pseudo-fields
      record_field(form, section_name, section_name, '') unless props.keys.include?('children')
      # Otherwise process the children
      process_section_fields(form, section_name, props['children'], '') if props.keys.include?('children')
    end

    def process_section_fields(form, section, children, path, namespace: '')
      # children will be a Hash if there is only one child. Wrap in array for consistent processing.
      children = [children] if children.is_a?(Hash)
      
      children.each{ |child|
        # Each child is a hash, and only the props value (always a Hash) is interesting
        child = child['props']

        unless namespace.empty?
          child['subpath'] = namespace unless child.has_key?('subpath')
        end

        # Now the permutations in child hash keys gets interesting
        chk_keys = child.keys - %w[collapsible collapsed tabular]

        case chk_keys.sort
        when ['name']
          # simple top-level field
          thispath = path.empty? ? "/#{child['name']}" : "#{path}/#{child['name']}"
          record_field(form, child['name'], section, thispath)
        when ['children']
          # unlabeled visual-only field grouping.
          thispath = path
          process_section_fields(form, section, child['children'], thispath)
        when ['children', 'name']
          # nested named field grouping
          if @panel_names.include?(child['name'])
            thispath = path
          else
            thispath = "#{path}/#{child['name']}"
          end
          process_section_fields(form, section, child['children'], thispath)
        when ['name', 'subpath']
          # simple top-level field in special namespace
          thispath = "#{path}/#{child['name']}"
          record_field(form, child['name'], section, thispath, namespace: child['subpath'])
        when ['children', 'subpath']
          # unlabled visual-only field grouping in special namespace
          # pass the namespace through since it is NOT set on all the children individually.
          thispath = "#{path}"
          process_section_fields(form, section, child['children'], thispath, namespace: child['subpath'])
        when ['children', 'name', 'subpath']
          # nested named field grouping in special namespace
          if @panel_names.include?(child['name'])
            thispath = path
          else
            thispath = "#{path}/#{child['name']}"
          end
          process_section_fields(form, section, child['children'], thispath, namespace: child['subpath'])
        end


       
      #ignorekeys = %w[name children collapsible collapsed tabular]
      #chk = child.keys - ignorekeys
      #expkeys = %w[key ref props _owner]
      #chk = child.keys - expkeys
      #puts "#{profile} #{rectype} #{form} #{section} #{child.keys.inspect}" unless child.keys.include?('props')
      # puts "#{profile} #{rectype} #{form} #{section} #{child.keys.inspect}" if chk.length > 0
      #puts "#{profile} #{rectype} #{form} #{section} #{child.keys.inspect}"
      #puts "#{profile} #{rectype} #{form} #{section} #{child.class}" unless child.is_a?(Hash)
      #puts "#{profile} #{rectype} #{form} #{props['name']}" unless props.include?('children')
        #puts "#{profile} #{rectype} #{form} #{section_name}"
      }
    end

    def record_field(form, fieldname, section, path, namespace: '')
      ns = namespace.empty? ? @rto.default_ns : namespace
      @fields[ns] = {} unless @fields.has_key?(ns)
      @fields[ns][fieldname] = {} unless @fields[ns].has_key?(fieldname)
      @fields[ns][fieldname][@profile] = {} unless @fields[ns][fieldname].has_key?(@profile)
      @fields[ns][fieldname][@profile][@rectype] = {} unless @fields[ns][fieldname][@profile].has_key?(@rectype)
      @fields[ns][fieldname][@profile][@rectype][form] = {'section' => section, 'path' => path}
    end
    
  end
  
end

