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
        puts CCU::Profile.new(p).rectypes.map{ |e| "  #{e}" }
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

    desc 'get_form_fields', 'get field info from form definitions for a given record type in a given profile'
    option :profile, :desc => 'the single profile to get fields for', :default => 'core'
    option :rectype, :desc => 'the record type to get fields for', :default => 'collectionobject'
    def get_form_fields
      CCU::FormFieldGetter.new(options[:profile], options[:rectype])
    end

    desc 'field_def_csv', 'write CSV containing field definition data'
    option :profile, :desc => 'the single profile to get fields for', :default => 'core'
    option :output, :desc => 'path to output file', :default => 'data/field_definitions.csv'
    def field_def_csv
      field_defs = []
      get_profiles.each {|profile|
        p = CCU::Profile.new(profile)
        p.field_defs.each{ |id, arr|
          arr.each{ |fd| field_defs << fd }
        }
      }
      CSV.open(options[:output], 'wb'){ |csv|
        csv << field_defs[0].csv_header
        field_defs.each{ |fd| csv << fd.to_csv }
      }
    end

    desc 'form_fields_csv', 'write CSV containing form field data'
    option :profile, :desc => 'the single profile to get fields for', :default => 'core'
    option :output, :desc => 'path to output file', :default => 'data/form_fields.csv'
    def form_fields_csv
      ffs = []
      get_profiles.each {|profile|
        p = CCU::Profile.new(profile)
        p.form_fields.each{ |ff| ffs << ff }
      }
      CSV.open(options[:output], 'wb'){ |csv|
        csv << ffs[0].csv_header
        ffs.each{ |ff| csv << ff.to_csv }
      }
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

    desc 'get_fields', 'get field info from field definitions for a given record type in a given profile'
    option :profile, :desc => 'the single profile to get fields for', :default => 'core'
    option :rectype, :desc => 'the record type to get fields for', :default => 'collectionobject'
    def get_fields
      CCU::FieldDefinitionGetter.new(options[:profile], options[:rectype])
    end

    desc 'compile_form_fields', 'combines form field info across profiles/record types'
    option :rectypes, :desc => 'comma-delimited list of record types to get fields for', :default => ''
    def compile_form_fields
      CCU::FormFieldCompiler.new(get_profiles, options[:rectypes].split(',').map(&:strip).sort)
    end
    
    desc 'testy', 'do things...'
    def testy

      get_profiles.each{ |profile|
        p = CCU::Profile.new(profile)
        #        f = p.field_defs
        puts "\n#{profile}"
        puts p.defined_fields_not_used
      }

      # ## Compare fields between two profiles
      # core = CCU::Profile.new('core')
      # core_fields = core.form_fields
      # cf = core_fields.map{ |f| f.id }

      # lhmc = CCU::Profile.new('lhmc')
      # lhmc_fields = lhmc.form_fields
      # lf = lhmc_fields.map{ |f| f.id }

      # puts lf - cf

      # get_profiles.each{ |profile|
      #   p = CCU::Profile.new(profile)
      #   f = p.field_defs
      #   h = {}
      #   f.each{ |id, arr|
      #      if id.include?('fieldLocVerbatim')
      #       if arr.length > 1
      #         if h.has_key?(arr.length)
      #           h[arr.length] << id
      #         else
      #           h[arr.length] = [id]
      #         end
      #       end
      #     end
      #   }
      #   puts "\n\n#{profile}"
      #   pp(h)
      #        fields.each{ |f| puts "#{profile} - #{f.id} - #{f.value_source}" if f.value_source && f.value_source.select{ |e| e.start_with?('other: ') }.count > 0 }

    end

  end
end
