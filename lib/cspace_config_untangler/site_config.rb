require 'cspace_config_untangler'

module CspaceConfigUntangler
  class SiteConfig
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
      case response.status
      when 200
        body = response.body
        return body.to_s
      else
        CCU::LOG.warn("REST API error: #{response.status} for #{apiurl}")
        puts "REST API error: #{response.status} for #{apiurl}. Returning nil."
        return nil
      end
    end
    
  end #class Config
end #module
