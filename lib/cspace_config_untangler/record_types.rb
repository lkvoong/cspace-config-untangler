require 'cspace_config_untangler'

module CspaceConfigUntangler
  class RecordType
    attr_reader :profile, :name, :id, :config, :ns, :panels, :input_tables,
      :forms, :nonunique_fields, :structured_date_treatment

    def initialize(profileobj, rectypename)
      @profile = profileobj
      @name = rectypename
      @id = "#{@profile.name}/#{@name}"
      @config = @profile.config['recordTypes'][@name]
      @ns = get_namespace
      @panels = get_panels
      @input_tables = get_input_tables
      @forms = get_forms
      @structured_date_treatment = @profile.structured_date_treatment
    end

    def field_defs
      if @config.dig('fields', 'document')
        defs = FieldDefinitionParser.new(self, @config['fields']['document'])
        return defs.field_defs
      else
        CCU::LOG.warn("#{profile.name} - #{name} has no field def hash")
      end
    end

    def form_fields
      all = []
      @forms.each{ |formname, form|
        all << form.fields
      }
      all_combined = all.flatten.uniq{ |f| f.id }
      return all_combined
    end

    def fields
      fields = form_fields.map{ |ff| CCU::Field.new(self, ff) }
      fields = explode_structured_date_fields(fields) if @structured_date_treatment == :explode
      fields = fields.flatten
      @nonunique_fields = get_nonunique_fields(fields)
      return fields
    end

    def explode_structured_date_fields(fields)
      sd_fields = fields.select{ |f| f.structured_date? }
      fields = fields - sd_fields
      sd_fields.each{ |f| fields << CCU::StructuredDateFieldMaker.new(f).fields(@profile) }
      fields
    end

    def get_nonunique_fields(fields)
      h = {}
      fields.each{ |f|
        path = [f.schema_path, f.name].flatten.join(' > ')
        if h.has_key?(path)
          h[path] << f
        else
          h[path] = [f]
        end
      }
      multi = h.select{ |path, farr| farr.length > 1 }
      return multi.keys
    end

    def mappings
      checkhash = {}
      mappings = fields.map{ |f| FieldMapper.new(field: f).mappings}.flatten
      # ensure unique datacolumn values for templates and mapper
        mappings.each do |mapping|
        if checkhash.key?(mapping.datacolumn)
          add = mapping.xpath.empty? ? mapping.namespace.split('_').last : mapping.xpath.last
          mapping.datacolumn = "#{add}_#{mapping.datacolumn}"
        else
          mapping.datacolumn = mapping.datacolumn
          checkhash[mapping.datacolumn] = nil
        end
      end
      mappings
    end

    # sets up "faux-required" fields for record types that do not have any required fields
    #   some unique ID field is required for batch import/processing
    def batch_mappings
      mappings = self.mappings
      if @name == 'movement'
        unless @profile.name.start_with?('botgarden')
          mapping = mappings.select{ |m| m.fieldname == 'movementReferenceNumber' }.first
          mapping.required = 'y'
        end
      end
      if @profile.name.start_with?('botgarden')
        if @name == 'loanout'
          mapping = mappings.select{ |m| m.fieldname == 'loanOutNumber' }.first
          mapping.required = 'y'
        end
        if @name == 'objectexit'
          mapping = mappings.select{ |m| m.fieldname == 'exitNumber' }.first
          mapping.required = 'y'
        end
      end
      mappings
    end
    
    private

    def get_forms
      if @config.dig('forms') && @name != 'blob'
        h = {}
        @config['forms'].keys.reject{ |e| e == 'mini' }.each{ |e| h[e] = CCU::Form.new(self, e) }
        return h
      else
        return {}
      end
    end


    def get_input_tables
      if @config.dig('messages', 'inputTable')
        h = {}
        @config['messages']['inputTable'].each{ |name, hash|
          h[name] = hash['id']
          @profile.messages[hash['id']] = {'name' => hash['defaultMessage'], 'fullName' => hash['defaultMessage']} unless @profile.messages.has_key?(hash['id'])
        }
        return h
      else
        return {}
      end
    end
    
    def get_panels
      if @config.dig('messages', 'panel')
        arr = []
        
        @config['messages']['panel'].keys.each{ |panelname|
          arr << panelname
          
          msgs = @profile.messages
          id = @config['messages']['panel'][panelname]['id']
          label = @config['messages']['panel'][panelname]['defaultMessage']
          msgs[id] = {'name' => label, 'fullName' => label} 
        }
        return arr
      else
        return []
      end
    end
    
    def get_namespace
      docname = @config['serviceConfig']['documentName']
      return "ns2:#{docname}_common"
    end
  end
  
  class RecordTypes
    attr_reader :list
    attr_reader :profiles

    # profiles = array of profile name strings
    def initialize(profiles)
      @profiles = profiles
      all = {}
      @profiles.each{ |p|
        CCU::Profile.new(p).recordtypes.each{ |rectype| all[rectype] = '' }
      }
      @list = all.keys.sort
    end
  end

end
