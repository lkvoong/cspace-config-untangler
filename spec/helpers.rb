module Helpers
  extend self
  
  def fixtures
    app_dir = File.realpath(File.join(File.dirname(__FILE__), '..'))
    File.join(app_dir, 'spec', 'fixtures')
  end

  def set_profile_release(version = '7_0')
    CCU.config.configdir = File.join(CCU.app_dir, 'data', 'config_holder', 'community_profiles', "release_#{version}")
  end

  class SetupGenerator
    attr_reader :profile, :rectype
    def initialize(profile:, rectype:, release: '7_0')
      Helpers.set_profile_release(release)
      CCU.config.main_profile_name = profile
      @profile = CCU::Profile.new(profile: CCU.main_profile, rectypes: [rectype])
      @rectype = @profile.rectypes.first
    end

    def field_def_config(namespace)
      parser = field_def_parser
      
      CCU::Fields::Def::Config.new(
        rectype: rectype,
        namespace: namespace,
        field_hash: parser.config[namespace],
        parser: parser
      )

    end
    
    def field_def_hash
      @field_def_hash ||= rectype.config['fields']['document']
    end

    def field_def_parser
      @field_def_parser ||= CCU::Fields::Def::Parser.new(rectype, field_def_hash)
    end

    def namespace_field_parser(namespace, config = nil)
      cfg = config ? config : field_def_config(namespace)
      CCU::Fields::Def::NamespaceFieldParser.new(cfg)
    end
  end
end
