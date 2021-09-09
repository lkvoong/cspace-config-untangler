# frozen_string_literal: true

require_relative 'field_config_child'
require_relative '../value_sources/type_extractor'
require_relative '../../track_attributes'

module CspaceConfigUntangler
  module Fields
    module Definition
      class FieldDefinition < FieldConfigChild
        include CCU::TrackAttributes
        attr_reader :name, :ns, :ns_for_id, :id,
          :schema_path,
          :repeats, :in_repeating_group,
          :data_type, :value_source, :value_list,
          :required,
          :profile, :rectype

        def initialize(fdp, name, config, parent)
          super(fdp, name, config, parent)
          @config = @config['[config]']
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
          if @config.dig('required') && @config['required'] == true
            return 'y'
          else
            return 'n'
          end
        end

        def set_value_sources
          type = CCU::Fields::ValueSources::TypeExtractor.call(@config)
          return unless type

          
          sources = CCU::Fields::ValueSources::SourceExtractor.call(type, @config)
          data = @config.dig('view', 'props')
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
          val = @config.dig('dataType')
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
          if @parent.is_a?(CCU::Fields::Def::Grouping) && @parent.is_structured_date?
            @id = "ext.structuredDate.#{@name}"
          elsif @parent.is_a?(CCU::Fields::Def::Grouping) && @parent.schema_path.include?('localityGroupList')
            @id = "ext.locality.#{@name}"
          elsif @config.dig('extensionName')
            @id = "ext.structuredDate.#{@name}" if @config['extensionName'] == 'structuredDate'
            @id = "ext.dimension.#{@name}" if @config['extensionName'] == 'dimension'
            @id = "ext.address.#{@name}" if @config['extensionName'] == 'address'
            @id = "ext.locality.#{@name}" if @config['extensionName'] == 'locality'
            # handles weirdness described at:
            #  https://collectionspace.atlassian.net/browse/DRYD-863
          elsif @id == 'approvalGroupField.approvalGroup'
            @id = "#{@ns.sub('ns2:', '')}.approvalGroup"
          else
            @id = "#{@ns_for_id.sub('ns2:', '')}.#{@name}"
          end
        end
      end
    end
  end
end
