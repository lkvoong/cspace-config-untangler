require 'cspace_config_untangler'

module CspaceConfigUntangler
  class ProfileOptionLists
    attr_reader :list
    attr_reader :config
    attr_reader :profile

    # profiles = array of profile name strings
    def initialize(profile)
      @profile = profile
      @list = []
      get_profile_option_lists
    end

    private

    def get_profile_option_lists
      @config = CCU::Profile.new(@profile).config.dig('optionLists')
      @list = @config.keys
    end
  end #class ProfileAuthorities
end #module
