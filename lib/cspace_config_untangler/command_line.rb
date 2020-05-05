require 'cspace_config_untangler'

module CspaceConfigUntangler
  class CommandLine < Thor
    def initialize(*args)
      super(*args)
    end

    no_commands{
      def get_profiles
        all_profiles = [CCU::MAINPROFILE, CCU::PROFILES].flatten
        if options[:profiles].empty?
          return [CCU::MAINPROFILE]
        elsif options[:profiles] == 'all'
          return all_profiles
        else
          profiles = options[:profiles].split(',').map(&:strip)
          real_profiles = []
          profiles.each{ |p|
            if all_profiles.include?(p)
              real_profiles << p
            else
              puts "Unknown profile \"#{p}\" will be ignored..."
            end
          }
          return real_profiles.uniq
        end
      end
    }

    class_option :profiles,
      desc: 'Comma-separated list (NO SPACES) of non-main profiles you want to process. If not set, will run main profile only. If "all", will run all known profiles.',
      type: 'string',
      default: '',
      aliases: '-p'
    
    desc 'main_profile', 'print the name of the main profile'
    def main_profile
      puts CCU::MAINPROFILE
    end

    desc 'all_profiles', 'print the names of all known profiles'
    def all_profiles
      puts CCU::MAINPROFILE
      puts CCU::PROFILES
    end

    desc 'check_profiles', 'print the names of profiles that will be processed'
    def check_profiles
      profiles = get_profiles
      puts profiles
    end

    desc 'list_rec_types', 'lists record types in each profile'
    def list_rec_types
      get_profiles.each{ |p|
        puts "\n#{p}:"
        puts CCU::Profile.new(p).rectypes.map{ |e| "  #{e.name}" }
      }
    end

    desc 'readable_profiles', 'create file containing JSON that is not all one line'
    def readable_profiles
      get_profiles.each{ |p|
        profile = CCU::Profile.new(p).config
        File.open("#{CCU::CONFIGDIR}/#{p}_readable.json", 'w'){ |f|
          f.puts JSON.pretty_generate(profile)
        }
      }
    end
    
    desc 'extensions_by_profile', 'list all extensions used in profiles, and list which profile uses each'
    def extensions_by_profile
      exts = {}
      get_profiles.each{ |p|
        CCU::Profile.new(p).extensions.each{ |ext|
          if exts.has_key?(ext)
            exts[ext] << p
          else
            exts[ext] = [p]
          end
        }
      }
      pp(exts)
    end

    desc 'write_field_defs', 'write file containing field definition data'
    option :profile, :desc => 'the profile(s) to get fields for', :default => 'core'
    option :rectype, :desc => 'the record type(s) to get fields for', :default => 'all'
    option :format, :desc => 'output format: csv or json', :default => 'csv'
    option :output, :desc => 'path to output file', :default => 'data/field_definitions.csv'
    def write_field_defs
      field_defs = []
      get_profiles.each {|profile|
        p = CCU::Profile.new(profile)
        if options[:rectype] == 'all'
          rts = p.rectypes.map{ |rt| rt.name }
        else
          rts = options[:rectype].split(',').map{ |e| e.strip }  
        end
        p.field_defs.each{ |id, arr|
          arr.each{ |fd| field_defs << fd if rts.include?(fd.rectype) }
        }
      }

      case options[:format]
      when 'csv'
        CSV.open(options[:output], 'wb'){ |csv|
          csv << field_defs[0].csv_header
          field_defs.each{ |fd| csv << fd.to_csv }
        }
      when 'json'
        File.open(options[:output], 'w'){ |file|
          file.write(JSON.pretty_generate(field_defs.map{ |fd| fd.to_h }))
        }
      end
    end

    desc 'write_form_fields', 'write file containing form field data'
    option :profile, :desc => 'the profile(s) to get fields for', :default => 'core'
    option :rectype, :desc => 'the record type(s) to get fields for', :default => 'all'
    option :format, :desc => 'output format: csv or json', :default => 'csv'
    option :output, :desc => 'path to output file', :default => 'data/form_fields.csv'
    def write_form_fields
      form_fields = []
      get_profiles.each {|profile|
        p = CCU::Profile.new(profile)
        if options[:rectype] == 'all'
          rts = p.rectypes.map{ |rt| rt.name }
        else
          rts = options[:rectype].split(',').map{ |e| e.strip }  
        end
        p.form_fields.each{ |ff| form_fields << ff if rts.include?(ff.rectype) }
      }

      case options[:format]
      when 'csv'
        CSV.open(options[:output], 'wb'){ |csv|
          csv << form_fields[0].csv_header
          form_fields.each{ |ff| csv << ff.to_csv }
        }
      when 'json'
        File.open(options[:output], 'w'){ |file|
          file.write(JSON.pretty_generate(form_fields.map{ |ff| ff.to_h }))
        }
      end
    end

    desc 'fields_csv', 'write CSV containing form field data'
    option :profile, :desc => 'the single profile to get fields for', :default => 'core'
    option :output, :desc => 'path to output file', :default => 'data/fields.csv'
    def fields_csv
      fs = []
      get_profiles.each {|profile|
        p = CCU::Profile.new(profile)
        p.fields.each{ |f| fs << f }
      }
      CSV.open(options[:output], 'wb'){ |csv|
        csv << fs[0].csv_header
        fs.each{ |f| csv << f.to_csv }
      }
    end
    
  end #class Thor::CommandLine
end #module
