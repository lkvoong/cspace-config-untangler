require 'cspace_config_untangler'

module CspaceConfigUntangler
  class Form
    attr_reader :rectype, :name, :config, :fields

    def initialize(rectypeobj, formname)
      @rectype = rectypeobj
      @name = formname
      @config = get_config
      @fields = []
      get_form_fields
    end

    private

    def get_config
      return @rectype.config['forms'][@name]['template']['props']
    end

    def get_form_fields
      CCU::FormProps.new(self, @config)
    end
  end #class Form

  class FormProps
    attr :form, :panel, :name, :ui_path, :ns, :is_panel, :is_ext

    def initialize(formobj, hash, parent = nil)
      @form = formobj
      @hash = hash
      @parent = parent

      
      @name = get_name
      @is_panel = @form.rectype.panels.keys.include?(@name)
      @is_ext = @is_panel ? @form.rectype.profile.extensions.include?(@name) : false
      
      @panel = get_panel

      @ns = get_ns
      
      @ui_path = build_ui_path

      if @hash.dig('children')
        CCU::FormChildren.new(@form, self, @hash['children'])
      elsif @name == 'contact' && @form.rectype.profile.extensions.include?(@name)
        process_contact_panel
      elsif @name.empty?
        profile = @form.rectype.profile.name
        rectype = @form.rectype.name
        CCU::LOG.warn("FORM STRUCTURE: #{profile} - #{rectype} - #{@form.name} contains empty hash under #{@parent.ui_path}")
      else
        @form.fields << CCU::FormField.new(self)
      end
    end

    private

    def process_contact_panel
      @hash = @form.rectype.profile.config['recordTypes']['contact']['forms']['default']['template']['props']['children']['props']
      @is_panel = true
      @is_ext = true
      @panel = @form.rectype.profile.config['recordTypes']['contact']['messages']['panel']['info']['id']
      @ns = @form.rectype.profile.config['recordTypes']['contact']['fields']['document']['[config]']['view']['props']['defaultChildSubpath']
      @ui_path = build_ui_path
      CCU::FormChildren.new(@form, self, @hash['children'])
    end
    
    def get_panel
      if @is_panel
        return @form.rectype.panels[@name][:id]
      elsif @parent
        return @parent.panel
      else
        return ''
      end
    end
    
    def get_name
      if @hash.dig('name')
        @name = @hash['name']
      else
        @name = ''
      end
    end
    
    def get_ns
      if @parent
        ns = @parent.ns
      else
        ns = @form.rectype.ns
      end

      if @is_ext
        ns = "ext.#{@name}"
      end

      ns = @hash['subpath'] if @hash.dig('subpath') && !@parent.is_ext
      return ns        
    end
    
    def build_ui_path
      return [] if @name == 'document'
      return [] if @is_panel
      path = @parent ? @parent.ui_path : []
      if is_input_table
        path << @form.rectype.input_tables[@name][:id]
      elsif @hash.dig('children') && !@name.empty?
        path << "#{@ns.sub('ns2:', '')}.#{@name}"
      else
        # skip
      end
      return path
    end

    def is_input_table
      return true if @form.rectype.input_tables.keys.include?(@name) && @hash['children']
    end
  end

  class FormField
    attr_reader :name, :ns, :panel, :path, :id

    def initialize(propsobj)
      @name = propsobj.name
      @panel = propsobj.panel
      @ns = propsobj.ns
      @path = propsobj.ui_path
      @id = "#{@ns.sub('ns2:', '')}.#{@name}"
    end
  end
  

  class FormChildren

    def initialize(formobj, parentprops, data)
      @form = formobj
      @parent = parentprops
      @children = standardize_form_data(data)
      @children.each{ |child| CCU::FormProps.new(@form, child['props'], @parent) }
    end

    # if there is only one child, it gets created as a hash
    # if there are multiple children, they are an array of hashes
    # turns a single child into an array containing one hash
    def standardize_form_data(data)
      if data.is_a?(Hash)
        result = [data]
      elsif data.is_a?(Array)
        result = data
      end
      report_non_nil_and_missing_keys(result)
      return result
    end

    # form children have keys: key, ref, props, and _owner
    # I'm proceeding based on the assumption that I only care about props because
    #  the others are always nil
    # This logs any non-nil values for key, ref, or _owner so I can inspect
    def report_non_nil_and_missing_keys(data)
      data.each{ |h|
        %w[key ref _owner].each{ |k| check_key(h, k) }
      }
    end

    def check_key(hash, key)
      if hash.has_key?(key)
        # check that it is nil
      else
        CCU::LOG.warn("FORM STRUCTURE: #{parent.form.name}")
      end
    end
    
    
  end #class FormChildren
  
end #module
