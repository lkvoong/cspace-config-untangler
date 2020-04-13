require 'cspace_data_config'

module CspaceDataConfig
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
      @config = CDC::Profile.new(@profile).config.dig('optionLists')
      @list = @config.keys
    end
  end #class ProfileAuthorities
end #module
