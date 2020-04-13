require 'cspace_config_untangler'

module CspaceConfigUntangler
  class Config
    attr_reader :profile
    attr_reader :url_base
    attr_reader :user
    attr_reader :pw
    
    def initialize(profile, dev = 'false')
      config = YAML.load(File.read('data/profile_config.yaml'))['profiles'][profile]
      if config['setup'] == 'standard'
        @url_base = dev == 'true' ? "#{profile}.dev.collectionspace.org" : "#{profile}.collectionspace.org"
        @pw = 'Administrator'
        @user = "admin@#{@url_base}"
      else
        @url_base = dev == 'true' ? config['dev']['base'] : config['prod']['base']
        @user = dev == 'true' ? config['dev']['user'] : config['prod']['user']
        @pw = dev == 'true' ? config['dev']['pw'] : config['prod']['pw']
      end
      @url_base = "https://#{@url_base}"
    end #def initialize

    def rest(path)
      apiurl = "#{url_base}/cspace-services#{path}"
      response = HTTP.basic_auth(
        user: @user,
        pass: @pw
      ).get(apiurl)
      body = response.body
      return body.to_s
    end
    
  end #class Config
end #module
