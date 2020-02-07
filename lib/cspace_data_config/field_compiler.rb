require 'cspace_data_config'

module CspaceDataConfig
  class FieldCompiler
    attr_reader :profiles
    attr_reader :rectypes
    attr_reader :form_fields
    attr_reader :ff
    # profiles = array of profile names
    # rectypes (optional) = Array. Default = empty, which will be replaced by *all* rectypes
    #   from the given profile
    def initialize(profiles, rectypes = [])
      @profiles = profiles
      @rectypes = rectypes
      @form_fields = []
      set_rectypes
      clean_rectypes
      @profiles.each{ |profile|
        po = CDC::Profile.new(profile)
        @rectypes.each{ |rectype|
          if po.recordtypes.include?(rectype)
          rt = CDC::RecordType.new(profile, rectype)
          @form_fields << rt.form_fields.fields unless rt.form_fields.empty?
          else
            #puts "WARNING: #{profile} does not include record type: #{rectype}"
          end
        }
      }
      @ff = {}
      compile_form_fields
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
    
    def set_rectypes
      if @rectypes.empty?
        rts = {}
        @profiles.each{ |p|
          CDC::Profile.new(p).recordtypes.each{ |rt| rts[rt] = '' }
        }
        @rectypes = rts.keys.sort
      end
    end

    def clean_rectypes
      ignore = %w[account authrole batch batchinvocation blob report vocabulary]
      @rectypes = @rectypes - ignore
    end

  end

end

