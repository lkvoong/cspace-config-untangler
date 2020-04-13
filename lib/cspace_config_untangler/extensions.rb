require 'cspace_config_untangler'

module CspaceConfigUntangler
  class ProfileExtensions
    attr_reader :config

    def initialize(profile)
      @config = CCU::Profile.new(profile).config['extensions']
    end
  end
  
  class Extensions
    attr_reader :hash
    attr_reader :rectypes

    # profiles = array of profile name strings
    def initialize(profiles)
      @rectypes = CCU::RecordTypes.new(profiles).list
      populate_initial_hash(profiles)
      sort_out_details
    end

    def print
      @hash.each{ |ext, hash|
        if hash[:adds_data_types].empty?
          puts "\nExtension #{ext.upcase} modifies"
        else
          puts "\nExtension #{ext.upcase} adds #{hash[:adds_data_types].join(', ')} to"
        end
        hash[:profiles].each{ |profile, rectypes|
          puts "  profile:#{profile.upcase}"
          rectypes.each{ |rt| puts "    record:#{rt.upcase}" }
        }
      }
    end
    
    private

    def populate_initial_hash(profiles)
      @hash = {}
      profiles.each{ |p|
        profile = CCU::Profile.new(p)
        config = profile.config
        profile.extensions.each{ |ext|
          ext_keys = config['extensions'][ext].keys
          if @hash.has_key?(ext)
            @hash[ext][profile.name] = ext_keys
          else
            @hash[ext] = {profile.name => ext_keys}
          end
        } #unless profile.extensions.empty?
      }
    end
    
    def sort_out_details
      new = {}
      @hash.each{ |ext, profiles|
        new[ext] = {:adds_data_types => [],
                    :profiles => {}}
        profiles.each{ |profile, arr|
          new[ext][:profiles][profile] = []
          arr.each{ |v|
            if @rectypes.include?(v)
              new[ext][:profiles][profile] << v
            else
              new[ext][:adds_data_types] << v unless new[ext][:adds_data_types].include?(v)
            end
          }
        }
      }
      @hash = new
    end
  end
end
