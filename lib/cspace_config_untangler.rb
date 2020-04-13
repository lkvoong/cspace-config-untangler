# standard library
require 'csv'
require 'json'
require 'logger'
require 'pp'
require 'yaml'

# external gems
require 'bundler/setup'
require 'http'
require 'nokogiri'
require 'pry'
require 'thor'

module CspaceConfigUntangler
  ::CCU = CspaceConfigUntangler
  autoload :VERSION, 'cspace_config_untangler/version'
  autoload :CommandLine, 'cspace_config_untangler/command_line'

  autoload :Config, 'cspace_config_untangler/config'
  autoload :FormFieldCompiler, 'cspace_config_untangler/field_compiler'
  autoload :FieldData, 'cspace_config_untangler/field_getter'
  autoload :FieldGetter, 'cspace_config_untangler/field_getter'
  autoload :FieldDefinitionGetter, 'cspace_config_untangler/field_getter'
  autoload :FormFieldGetter, 'cspace_config_untangler/field_getter'
  autoload :InputTable, 'cspace_config_untangler/input_tables'
  autoload :InputTables, 'cspace_config_untangler/input_tables'
  autoload :Panel, 'cspace_config_untangler/panels'
  autoload :Panels, 'cspace_config_untangler/panels'
  autoload :Profile, 'cspace_config_untangler/profile'
  autoload :ProfileExtensions, 'cspace_config_untangler/extensions'
  autoload :ProfileAuthorities, 'cspace_config_untangler/authorities'
  autoload :ProfileOptionLists, 'cspace_config_untangler/option_lists'
  autoload :ProfileVocabularies, 'cspace_config_untangler/vocabularies'
  autoload :Extensions, 'cspace_config_untangler/extensions'
  autoload :RecordTypes, 'cspace_config_untangler/record_types'
  autoload :RecordType, 'cspace_config_untangler/record_types'
  
  def self.safe_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end

end
