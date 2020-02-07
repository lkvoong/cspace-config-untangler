require 'cspace_data_config'

module CspaceDataConfig
  class Profile
    attr_reader :name
    attr_reader :config
    attr_reader :recordtypes
    attr_reader :extensions
    
    def initialize(profile)
      @name = profile
      @config = JSON.parse(File.read("#{CDC::CONFIGDIR}#{@name}.json"))
      @recordtypes = @config['recordTypes'].keys
      @extensions = @config['extensions'].keys
    end
  end
end

=begin
@config['structDateOptionListNames']
 ['dateQualifiers']

@config['structDateVocabNames']
["dateera", "datecertainty", "datequalifier"]

@config > extensions > {extname} > [array of values]
EXAMPLES:
address:
["fields", "form"]

structuredDate:
["fields"]

locality:
["messages", "fields", "form"]
? special anthro overrides to messages?

nagpra:
["claim", "collectionobject"]

=end
