require 'cspace_config_untangler'

module CspaceConfigUntangler
  class ProfileComparison
    def initialize(profilearray, outputdir)
      profiles = profilearray.map{ |p| CCU::Profile.new(p) }
      @profiles = profiles.map{ |p| p.name }
      @output = "#{outputdir}/compare_#{@profiles[0]}_to_#{@profiles[1]}.csv"
      @fields = profiles.map{ |p| p.fields }.map{ |p| by_path(p) }
      @combined = combined_fields
      @diff = diff_combined
      @diff.each{ |k, arr| puts "#{k}: #{arr.size}" }
    end

    def write_csv
      headers = %w[record_type field diff_type details]
      CSV.open(@output, 'w', write_headers: true, headers: headers){ |csv|
        rows = []
        @diff.each{ |k, arr|
          if k.start_with?('not in')
            arr.each{ |f|
              row = [f.rectype]
              row << [f.schema_path, f.name].flatten.join(' < ')
              row << k
              row << ''
              rows << row
            }
          elsif k == 'source differences'
            arr.each{ |h|
              row = [h[0].rectype]
              row << [h[0].schema_path, h[0].name].flatten.join(' < ')
              row << k

              details = "#{@profiles[0].upcase}: #{h[0].value_source.join(',')}. #{@profiles[1].upcase}: #{h[1].value_source.join(',')}. "
              row << details
              rows << row
            }
          elsif k == 'ui path differences'
            arr.each{ |h|
              row = [h[0].rectype]
              row << [h[0].schema_path, h[0].name].flatten.join(' < ')
              row << k

              details = "#{@profiles[0].upcase}: #{h[0].ui_path.join(' > ')}. #{@profiles[1].upcase}: #{h[1].ui_path.join(' > ')}. "
              row << details
              rows << row
            }
          end
        }
        rows.each{ |r| csv << r }
      }
    end
    
    private

    def diff_combined
      diff = {
        "not in #{@profiles[0]}" => [],
        "not in #{@profiles[1]}" => [],
        'source differences' => [],
        'ui path differences' => []
      }
      
      @combined.each{ |id, hash|
        if hash[0].nil?
          diff["not in #{@profiles[0]}"] << hash[1]
        elsif hash[1].nil?
          diff["not in #{@profiles[1]}"] << hash[0]
        elsif hash[0].value_source.sort != hash[1].value_source.sort
          diff['source differences'] << hash
        elsif hash[0].ui_path != hash[1].ui_path
          diff['ui path differences'] << hash
        end
      }
      return diff
    end
    
    def combined_fields
      h = {}
      @fields.each{ |fhash| fhash.keys.each{ |k| h[k] = { 0 => nil, 1 => nil } } }
      @fields.each_with_index{ |fhash, i|
        fhash.each{ |path, f|
          h[path][i] = f
        }
      }
      return h
    end

    # receives field_defs hash
    # returns has by rectype + schema path + name
    def by_path(field_arr)
      h = {}
      field_arr.each{ |f|
        path = [f.rectype, f.schema_path, f.name].flatten
          h[path] = f
        }
      return h
    end

  end #class ProfileComparison
end #module
