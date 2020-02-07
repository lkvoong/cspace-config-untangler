require 'cspace_data_config'

module CspaceDataConfig
  class RecordTypes
    attr_reader :list
    attr_reader :profiles

    # profiles = array of profile name strings
    def initialize(profiles)
      @profiles = profiles
      all = {}
      @profiles.each{ |p|
        CDC::Profile.new(p).recordtypes.each{ |rectype| all[rectype] = '' }
      }
      @list = all.keys.sort
    end
  end

  class RecordType
    attr_reader :profile
    attr_reader :name
    attr_reader :id
    attr_reader :config
    attr_reader :docname
    attr_reader :default_ns
    attr_reader :form_fields

    def initialize(profile, rectype)
      @profile = profile
      @name = rectype
      @id = "#{profile}/#{rectype}"
      @config = CDC::Profile.new(profile).config['recordTypes'][rectype]
      @docname = @config['serviceConfig']['documentName']
      @default_ns = "ns2:#{@docname}_common"
    end

    def form_fields
      CDC::FormFieldGetter.new(@profile, @name)
    end
  end
end
