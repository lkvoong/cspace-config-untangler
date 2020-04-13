require 'cspace_config_untangler'

module CspaceConfigUntangler
  class ProfileAuthorities
    attr_reader :list
    attr_reader :profile

    # profiles = array of profile name strings
    def initialize(profile)
      @profile = profile
      @list = []
      get_profile_authorities
    end

    private

    def get_profile_authorities
      CCU::RecordTypes.new([profile]).list.each{ |rectype|
        config = CCU::RecordType.new(profile, rectype).config
        if config.dig('serviceConfig', 'serviceType') == 'authority'
          authtype = rectype
          config['vocabularies'].keys.reject{ |e| e == 'all' }.each{ |subtype|
            @list << "#{authtype}/#{subtype}"
          }
        end
      }
    end
  end #class ProfileAuthorities
end #module
