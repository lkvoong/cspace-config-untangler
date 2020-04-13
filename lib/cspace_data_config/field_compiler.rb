require 'cspace_data_config'

module CspaceDataConfig
  class FieldCompiler
    attr_reader :profiles
    attr_reader :rectypes
    attr_reader :profile_objs
    attr_reader :rectype_objs

    # profiles = array of profile names
    # rectypes (optional) = Array. Default = empty, which will be replaced by *all* rectypes
    #   from the given profile
    def initialize(profiles, rectypes = [])
      @profiles = profiles
      @rectypes = rectypes
      set_rectypes if @rectypes.empty?
      clean_rectypes
      
      @profile_objs = @profiles.map{ |profile| CDC::Profile.new(profile) }
      @rectype_objs = []
      @profile_objs.each{ |profile|
        @rectypes.each{ |rectype|
          if profile.recordtypes.include?(rectype)
            @rectype_objs << CDC::RecordType.new(profile.name, rectype)
          else
            #puts "WARNING: #{profile} does not include record type: #{rectype}"
          end
        }
      }
    end

    private

    def set_rectypes
        rts = {}
        @profiles.each{ |p|
          CDC::Profile.new(p).recordtypes.each{ |rt| rts[rt] = '' }
        }
        @rectypes = rts.keys.sort
    end

    def clean_rectypes
      ignore = %w[account authrole batch batchinvocation blob report vocabulary]
      @rectypes = @rectypes - ignore
    end
  end #class FieldCompiler

  class FieldDefinitionCompiler < FieldCompiler
    attr_reader :fields
    
    def initialize(profiles, rectypes = [])
      super
      compile_field_definitions
    end

    private

    def compile_field_definitions
    end
  end
  
  class FormFieldCompiler < FieldCompiler
    attr_reader :form_fields
    attr_reader :ff
    def initialize(profiles, rectypes = [])
      super
      @form_fields = []
      @rectype_objs.each{ |rectype|
        @form_fields << rectype.form_fields.fields unless rectype.form_fields.empty?
      }
      @ff = {}
      compile_form_fields
      pp(@form_fields)
    end

    def rec_type_ct_chk
      @ff.each{ |ns, fh|
        fh.each{ |field, ph|
          rectypes = ph.values.flatten
          if rectypes.length > 1
            puts "\n#{ns}:#{field}"
            pp(@ff[ns][field])
          end
          }
      }
    end
    
    def form_fields_csv
      headers = %w[fullname namespace field] + ["in_#{CDC::MAINPROFILE}?"] + CDC::PROFILES.map{ |e| "in_#{e}?" }
      csvpath = 'data/form_field_summary.csv'
      CSV.open(csvpath, 'wb'){ |csv|
        csv << headers
        @ff.each{ |ns, fh|
          fh.each{ |field, ph|
            fullname = "#{ns}:#{field}"
            csv << [fullname, ns, field]
          }
        }
      }
      table = CSV.read(csvpath, headers: true)
      table.each{ |row|
        profiles = @ff[row['namespace']][row['field']].keys
        headers = profiles.map{ |e| "in_#{e}?" }
        headers.each{ |hdr| row[hdr] = 'y' }
      }

      CSV.open(csvpath, 'wb'){ |csv|
        csv << table.headers
        table.each{ |row| csv << row }
      }
    end

    private

    def compile_form_fields
      @form_fields.each{ |ffhash|
        ffhash.each{ |namespace, fieldhash|
          fieldhash.each{ |field, profilehash|
            profilehash.each{ |profile, rectypehash|
              @ff[namespace] = {} unless @ff.has_key?(namespace)
              @ff[namespace][field] = {} unless @ff[namespace].has_key?(field)
              @ff[namespace][field][profile] = [] unless @ff[namespace][field].has_key?(profile)
              @ff[namespace][field][profile] << rectypehash.keys[0]
            }
          }
        }
      }
    end
   
  end

end

