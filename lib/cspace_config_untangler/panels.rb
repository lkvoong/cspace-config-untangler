require 'cspace_config_untangler'

module CspaceConfigUntangler
  class Panel
    attr_reader :profile
    attr_reader :rectype
    attr_reader :id
    attr_reader :name
    attr_reader :fields

    def initialize(profile, rectype, config)
      @profile = profile
      @rectype = rectype
      @id = config['id']
      @name = config['defaultMessage']
    end
    
  end #class Panel
  
  class Panels
    attr_reader :config
    attr_reader :profile
    attr_reader :rectype
    attr_reader :panels

    def initialize(profile, rectype)
      @profile = profile
      @rectype = rectype
      @config = CCU::Profile.new(@profile).config.dig('recordTypes', rectype, 'messages', 'panel')
      @panels = @config ? get_panels : nil
    end

    private

    def get_panels
      @config.keys.each{ |panel|
        CCU::Panel.new(@profile, @rectype, @config[panel])
      }
    end
  end #class Panels
end #module
