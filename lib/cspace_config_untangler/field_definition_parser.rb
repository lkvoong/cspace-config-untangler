require 'cspace_config_untangler'

module CspaceConfigUntangler
  module FieldParsing
    ::FieldParsing = CspaceConfigUntangler::FieldParsing
    class FieldDefinitionParser
      ::FieldDefinitionParser = CspaceConfigUntangler::FieldParsing::FieldDefinitionParser
      attr_reader :rectype, :config, :field_defs

      def initialize(rectypeobj, hash)
        @rectype = rectypeobj
        @config = hash
        @ns = @config['[config]']['view']['props']['defaultChildSubpath']
        @field_defs = []
        get_field_defs
      end

      private

      def get_field_defs
        @config.each{ |k, h|
          case k
          when '[config]'
            next
          when 'ns2:collectionspace_core'
            next
          when 'rel:relations-common-list'
            #do relations processing
          else
            FieldNamespace.new(self, k, h)
          end
        }
      end
    end #class FieldDefinitionParser
    
    class FieldNamespace
      ::FieldNamespace = CspaceConfigUntangler::FieldParsing::FieldNamespace
      # fdp = FieldDefinitionParser
      attr_reader :fdp, :ns, :ns_for_id, :config

      def initialize(fdpobj, ns, hash)
        @fdp = fdpobj
        @ns = ns
        @ns_for_id = @ns
        if @ns.start_with?('ns2:contacts_')
          @config = @fdp.rectype.profile.config['recordTypes']['contact']['fields']['document'][@ns]
        elsif @ns == 'ns2:blobs_common'
          @config = @fdp.rectype.profile.config['recordTypes']['blob']['fields']['document'][@ns]
        elsif @ns == 'ns2:collectionobjects_accessionuse'
          @ns_for_id = 'ext.accessionuse'
          @config = hash
        elsif @ns == 'ns2:propagations_common'
          @ns_for_id = 'ns2:propagation_common'
          @config = hash
        elsif @ns == 'ns2:conditionchecks_variablemedia'
          @ns_for_id = 'ext.technicalChanges'
          @config = hash
        elsif @ns == 'ns2:acquisitions_commission'
          @ns_for_id = 'ext.commission'
          @config = hash
        else
          @config = hash
        end
        @config.delete('[config]')

        @config.each{ |k, h|
          if h.keys.length == 1 && h.keys == ['[config]']
            FieldVerifier.new(@fdp, k, h, self)
          elsif h.keys.length > 1
            FieldGrouping.new(@fdp, k, h, self)
          else
            CCU::LOG.warn("FIELD DEFINITION STRUCTURE: #{@fdp.rectype.profile.name} - #{@fdp.rectype.name} - #{@ns} - has unexpected keys")
          end
        }
      end
    end

    class FieldVerifier
      ::FieldVerifier = CspaceConfigUntangler::FieldParsing::FieldVerifier
      def initialize(fdp, name, config, parent)
        skip = %w[csid inAuthority refName shortIdentifier]
        fdp.field_defs << FieldDefinition.new(fdp, name, config, parent) unless skip.include?(name)
      end
    end

    class FieldConfigChild
      ::FieldConfigChild = CspaceConfigUntangler::FieldParsing::FieldConfigChild
      attr_reader :name, :ns, :ns_for_id, :id,
        :schema_path,
        :repeats, :in_repeating_group

      def initialize(fdp, name, config, parent)
        @fdp = fdp
        @config = config
        @parent = parent
        
        @name = name
        @ns = parent.ns
        @ns_for_id = parent.ns_for_id
        update_id_ns
        #      binding.pry if @name == 'visualPreferencesList'
        @id = get_id
        get_message('name') if @id
        get_message('fullName') if @id
        @schema_path = set_schema_path
        @repeats = set_repeats
        @in_repeating_group = set_group_repeats
      end

      def is_structured_date?
        return true if @config.dig('[config]', 'dataType') == 'DATA_TYPE_STRUCTURED_DATE'
        return true if @config.dig('dateLatestDay')
        return false
      end
      
      private

      def update_id_ns
        @ns_for_id = "ext.#{@config['extensionName']}" if @config.dig('extensionName')
        @ns_for_id = "ext.#{@config['[config]']['extensionName']}" if @config.dig('[config]', 'extensionName')
      end
      
      def set_schema_path
        if @parent.is_a?(FieldNamespace)
          return []
        else
          return @parent.schema_path.clone
        end
      end

      def get_message(key)
        messages = @fdp.rectype.profile.messages
        id = "field." + @id

        messages[id] = {} unless messages.has_key?(id)
        
        messages[id][key] = @config.dig('[config]', 'messages', key, 'defaultMessage')
      end

      def get_id
        id = @config.dig('[config]', 'messages', 'name', 'id')
        id = @config.dig('[config]', 'messages', 'fullName', 'id') if id.nil?

        if id
          # the following account for typos in the ui config
          id = id.gsub('acquistion', 'acquisition')
          id = id.sub('despositor', 'depositor')
          id = id.sub('webAddressTypeType', 'webAddressType')
          id = id.sub('graveAssocCodes', 'graveAssocCode')
          id = id.sub('persons_common.forename', 'persons_common.foreName')
          id = id.sub('persons_common.surname', 'persons_common.surName')
          id = id.sub('propagations_common', 'propagation_common')
          # match form used in namespace/subpaths
          id = id.sub('_naturalhistory.', '_naturalhistory_extension.')
        end

        return id.sub('field.', '').sub(/\.name$/, '').sub('.fullName', '') if id
      end

      def set_repeats
        if @config.dig('[config]', 'repeating') == true
          return 'y'
        else
          return 'n'
        end
      end

      def set_group_repeats
        if @parent.is_a?(FieldNamespace)
          return 'n/a'
        elsif @parent.repeats == 'y'
          return 'y'
        elsif @parent.repeats == 'n' && @parent.in_repeating_group == 'y'
          return 'as part of larger repeating group'
        else
          return 'n'
        end
      end

    end

    class FieldDefinition < FieldConfigChild
      ::FieldDefinition = CspaceConfigUntangler::FieldParsing::FieldDefinition
      include CCU::TrackAttributes
      attr_reader :name, :ns, :ns_for_id, :id,
        :schema_path,
        :repeats, :in_repeating_group,
        :data_type, :value_source, :value_list,
        :required,
        :profile, :rectype

      def initialize(fdp, name, config, parent)
        super(fdp, name, config, parent)
        set_id
        @data_type = set_datatype
        @value_source = []
        @value_list = []
        set_value_sources
        @required = set_required
        clean_up
        
      end

      def to_h
        attrs = self.attr_readers.map{ |e| '@' + e.to_s }.map{ |e| e.to_sym }
        h = {}
        attrs.each{ |a| h[a] = self.instance_variable_get(a) }
        return h
      end

      def csv_header
        return %w[profile record_type namespace field_id field_name schema_path required repeats group_repeats data_type data_source option_list_values]
      end
      
      def to_csv
        arr = [@profile, @rectype, @ns, @id]
        @name ? arr << @name : arr << ''
        @schema_path ? arr << @schema_path.join(' > ') : arr << ''
        @required ? arr << @required : arr << ''
        @repeats ? arr << @repeats : arr << ''
        @in_repeating_group ? arr << @in_repeating_group : arr << ''
        @data_type ? arr << @data_type : arr << ''
        @value_source ? arr << @value_source.join(', ') : arr << ''
        @value_list ? arr << @value_list.join(', ') : arr << ''
        return arr
      end
      
      private

      def clean_up
        @profile = @fdp.rectype.profile.name
        @rectype = @fdp.rectype.name
        @fdp = nil
        @config = nil
        @parent = nil
      end
      
      def set_required
        if @config.dig('[config]', 'required') && @config['[config]']['required'] == true
          return 'y'
        else
          return 'n'
        end
      end

      def set_value_sources
        data = @config.dig('[config]', 'view', 'props')
#        binding.pry if @name == 'contentConcept'
        return [] if data.nil?

        if data.has_key?('autoComplete') && !data.has_key?('source')
          CCU::LOG.warn("DATA SOURCES: #{@fdp.rectype.profile.name} - #{@fdp.rectype.name} - #{@ns} - #{@id} - Autocomplete defined with no source")
          return []
        end

        if data.has_key?('source')

          number_types = %w[accession archives claim conditioncheck conservation evaluation exhibition
                            indemnity insurance intake inventory library loanin loanout location media
                            movement objectexit pottag propagation study transport uoc valuationcontrol voucher]
          
          sources = data['source'].split(',')
          sources.each{ |source|
            if @fdp.rectype.profile.option_lists.include?(source)
              @value_source << "option list: #{source}"
              list = @fdp.rectype.profile.config.dig('optionLists', source, 'values')
              @value_list = list.sort if list
            elsif @fdp.rectype.profile.authorities.include?(source)
              @value_source << "authority: #{source}"
            elsif @fdp.rectype.profile.vocabularies.include?(source)
              @value_source << "vocabulary: #{source}"
            elsif source['/']
              # do nothing; authority not included in this profile is specified in field definition
              #  reused by multiple profiles
            elsif @name.end_with?('Number') && number_types.include?(source)
              # do nothing; defines number pattern or object/procedure linkage
            else
              CCU::LOG.warn("DATA SOURCES: #{@fdp.rectype.profile.name} - #{@fdp.rectype.name} - #{@ns} - #{@id} - Source value '#{source}' is not an option list, authority, or vocabulary")
              @value_source << "other: #{source}"
            end
          }
        end

      end

      def set_datatype
        val = @config.dig('[config]', 'dataType')
        val = val.sub('DATA_TYPE_', '') if val
        case val
        when nil
          return 'structured date group' if is_structured_date?
          return 'string'
        when 'INT'
          return 'integer'
        when 'FLOAT'
          return 'float'
        when 'BOOL'
          return 'boolean'
        when 'DATE'
          return 'date'
        when 'STRING'
          return 'string'
        when 'STRUCTURED_DATE'
          return 'structured date group'
        else
          return "TODO: handle unknown datatype: #{val}"
        end
      end

      def set_id
        if @parent.is_a?(FieldGrouping) && @parent.is_structured_date?
          @id = "ext.structuredDate.#{@name}"
        elsif @parent.is_a?(FieldGrouping) && @parent.schema_path.include?('localityGroupList')
          @id = "ext.locality.#{@name}"
        elsif @config.dig('[config]', 'extensionName')
          @id = "ext.structuredDate.#{@name}" if @config['[config]']['extensionName'] == 'structuredDate'
          @id = "ext.dimension.#{@name}" if @config['[config]']['extensionName'] == 'dimension'
          @id = "ext.address.#{@name}" if @config['[config]']['extensionName'] == 'address'
          @id = "ext.locality.#{@name}" if @config['[config]']['extensionName'] == 'locality'
          # handles weirdness described at:
          #  https://collectionspace.atlassian.net/browse/DRYD-863
        elsif @id == 'approvalGroupField.approvalGroup'
          @id = "#{@ns.sub('ns2:', '')}.approvalGroup"
        else
          @id = "#{@ns_for_id.sub('ns2:', '')}.#{@name}"
        end
      end

    end

    class FieldGrouping < FieldConfigChild
      ::FieldGrouping = CspaceConfigUntangler::FieldParsing::FieldGrouping
      attr_reader :repeats
      def initialize(fdp, name, config, parent)
        super(fdp, name, config, parent)
        @schema_path << @name
        
        if is_structured_date?
          FieldVerifier.new(@fdp, @name, @config, parent)
        else
          @config.each{ |k, h|
            unless k == '[config]'
              if h.keys.length == 1 && h.keys == ['[config]']
                FieldVerifier.new(@fdp, k, h, self)
              elsif h.keys.length > 1  
                FieldGrouping.new(@fdp, k, h, self)
              else
                CCU::LOG.warn("FIELD DEFINITION STRUCTURE: #{@fdp.rectype.profile.name} - #{@fdp.rectype.name} - #{@ns} - #{f} has unexpected keys")
              end
            end
          }
        end
      end

      private

    end
  end  
end #module
