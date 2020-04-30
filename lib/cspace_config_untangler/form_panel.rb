require 'cspace_config_untangler'

module CspaceConfigUntangler
  class FormPanel
    attr_reader :form, :id, :label, :fields

    def initialize(formobj, panelhash)
      @form = formobj
      @id = 
      @label = @form.rectype.panels[@id][:label]
      @fields = get_panel_fields
    end

    private

    def get_form_fields
      @config.each{ |panel| process_panel(panel) }
    end

    def process_panel(panel)
      # As of 2020-04-14, all key, ref, and _owner values at the panel level are nil
      panel = panel['props']
      panel_name = panel['name']
      if panel_name == 'contact'
        # figure out how to get fields from subrecord treated as extension
      else
        children = get_panel_children(panel)
      end
    end

    def get_panel_children(panel)
      children = panel['children']
      puts "#{children.class} -- #{rectype.id} #{panel['name']}"
    end
      
    def get_config
      config = @rectype.config['forms'][@name]['template']['props']['children']
      return standardize_form_data(config)
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
      report_non_nil_keys(data)
      return data
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
      
    end
    
    
  end #class Form
  
end #module
