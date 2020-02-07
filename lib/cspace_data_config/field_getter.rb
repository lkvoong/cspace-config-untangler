require 'cspace_data_config'

module CspaceDataConfig
  # extracts field info from a config
  class FieldGetter
    attr_reader :profile
    attr_reader :rectype
    attr_reader :rto # CDC::RecordType object
    attr_reader :config
    attr_reader :fields
    
    def initialize(profile, rectype)
      @profile = profile
      @rectype = rectype
      @rto = CDC::RecordType.new(@profile, @rectype)
      @config = @rto.config
      @fields = {}
      #puts "Getting field data for #{@profile} #{@rectype}..."
    end

    def empty?
      return true if @fields.empty?
      return false
    end
  end

  # We are getting a path hierarchy from the form data, but this is NOT the path that
  #  controls the nesting of XML fields. It's just for info's sake here. 
  class FormFieldGetter < FieldGetter
    attr_reader :forms
    def initialize(profile, rectype)
      super
      if has_forms?
        set_forms
        @forms.each{ |form| extract_fields(form) }
      end
      # puts "\n#{@rto.id}"
      # pp(@fields)
      return @fields
    end

    private

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
          thispath = "#{path}/#{child['name']}"
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
          thispath = "#{path}"
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

