require 'cspace_data_config'

module CspaceDataConfig
  class InputTable
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
  end #class InputTable
  
  class InputTables
    attr_reader :config
    attr_reader :profile
    attr_reader :rectype
    attr_reader :list

    def initialize(profile, rectype)
      @profile = profile
      @rectype = rectype
      @config = CDC::Profile.new(@profile).config.dig('recordTypes', rectype, 'messages', 'inputTable')
      @list = @config ? get_input_tables : nil
    end

    private

    def get_input_tables
      @config.keys.each{ |table|
        CDC::InputTable.new(@profile, @rectype, @config[table])
      }
    end
  end #class InputTables
end #module
