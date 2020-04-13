require 'cspace_data_config'

module CspaceDataConfig
  class CommandLine < Thor
    def initialize(*args)
      super(*args)
      CDC.const_set('MAINPROFILE', 'core')
      CDC.const_set('PROFILES', %w[anthro bonsai botgarden fcart herbarium lhmc materials ohc publicart])
      CDC.const_set('CONFIGDIR', 'data/configs/5_2')
      CDC.const_set('LOG', Logger.new('log.log'))
    end

    no_commands{
      def get_profiles
        all_profiles = [CDC::MAINPROFILE, CDC::PROFILES].flatten
        if options[:profiles].empty?
          return [CDC::MAINPROFILE]
        elsif options[:profiles] == 'all'
          return all_profiles
        else
          profiles = options[:profiles].split(',').map(&:strip)
          profiles << CDC::MAINPROFILE
          real_profiles = []
          profiles.each{ |p|
            if all_profiles.include?(p)
              real_profiles << p
            else
              puts "Unknown profile \"#{p}\" will be ignored..."
            end
          }
          return real_profiles
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
      puts CDC::MAINPROFILE
    end

    desc 'all_profiles', 'print the names of all known profiles'
    def all_profiles
      puts CDC::MAINPROFILE
      puts CDC::PROFILES
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
        puts CDC::Profile.new(p).record_types.map{ |e| "  #{e}" }
      }
    end

    desc 'pretty_print_profiles', 'create file containing JSON that is not all one line'
    def pretty_print_profiles
      get_profiles.each{ |p|
        profile = CDC::Profile.new(p).config
        File.open("#{CDC::CONFIGDIR}/#{p}_readable.txt", 'w'){ |f|
          f.puts JSON.pretty_generate(profile)
        }
      }
    end
    
    desc 'extensions_by_profile', 'list all extensions used in profiles, and list which profile uses each'
    def extensions_by_profile
      CDC::Extensions.new(get_profiles).print
    end

    desc 'get_form_fields', 'get field info from form definitions for a given record type in a given profile'
    option :profile, :desc => 'the single profile to get fields for', :default => 'core'
    option :rectype, :desc => 'the record type to get fields for', :default => 'collectionobject'
    def get_form_fields
      CDC::FormFieldGetter.new(options[:profile], options[:rectype])
    end

    desc 'get_fields', 'get field info from field definitions for a given record type in a given profile'
    option :profile, :desc => 'the single profile to get fields for', :default => 'core'
    option :rectype, :desc => 'the record type to get fields for', :default => 'collectionobject'
    def get_fields
      CDC::FieldDefinitionGetter.new(options[:profile], options[:rectype])
    end

    desc 'compile_form_fields', 'combines form field info across profiles/record types'
    option :rectypes, :desc => 'comma-delimited list of record types to get fields for', :default => ''
    def compile_form_fields
      CDC::FormFieldCompiler.new(get_profiles, options[:rectypes].split(',').map(&:strip).sort)
    end
    
    desc 'testy', 'do things...'
    def testy

#      fc = CDC::FieldCompiler.new(get_profiles)
#      fc.form_fields_csv
      
      profile = 'core'
      rectype = 'collectionobject'
      form = 'default'
      #      sectionname = 'condition'

#      CDC::ProfileAuthorities.new(profile)

      CDC::FieldDefinitionGetter.new(profile, rectype)
#      pp(CDC::FormFieldGetter.new(profile, rectype).fields)

#      pp(CDC::FieldData.new('namespace here').hash)
      #config = CDC::Profile.new(profile).config
      #fields = config['recordTypes'][rectype]['fields']
      #pp(fields['document']['ns2:collectionobjects_anthro']['anthroOwnershipGroupList']['anthroOwnershipGroup']['anthroOwner'])
      
      #form = config['recordTypes'][rectype]['forms'][form]['template']
      #pp(form.keys)
      #pp(form['serviceConfig'])
      
      #sections = form['props']['children']
      #pp(sections)

      #sections.each{ |section|
      #  name = section['props'].keys.include?('name') ? section['props']['name'] : ''
      #  pp(section['props']['children']) if name == sectionname
      #}

#      s.each{ |sp|
#        sprops = sp['props']
#        pp(sprops) unless sprops.keys.include?('children')
#      }
    end

  end
end
