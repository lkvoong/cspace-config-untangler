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

module CspaceDataConfig
  ::CDC = CspaceDataConfig
  autoload :VERSION, 'cspace_data_config/version'
  autoload :CommandLine, 'cspace_data_config/command_line'

  autoload :Config, 'cspace_data_config/config'
  autoload :FormFieldCompiler, 'cspace_data_config/field_compiler'
  autoload :FieldData, 'cspace_data_config/field_getter'
  autoload :FieldGetter, 'cspace_data_config/field_getter'
  autoload :FieldDefinitionGetter, 'cspace_data_config/field_getter'
  autoload :FormFieldGetter, 'cspace_data_config/field_getter'
  autoload :InputTable, 'cspace_data_config/input_tables'
  autoload :InputTables, 'cspace_data_config/input_tables'
  autoload :Panel, 'cspace_data_config/panels'
  autoload :Panels, 'cspace_data_config/panels'
  autoload :Profile, 'cspace_data_config/profile'
  autoload :ProfileExtensions, 'cspace_data_config/extensions'
  autoload :ProfileAuthorities, 'cspace_data_config/authorities'
  autoload :ProfileOptionLists, 'cspace_data_config/option_lists'
  autoload :ProfileVocabularies, 'cspace_data_config/vocabularies'
  autoload :Extensions, 'cspace_data_config/extensions'
  autoload :RecordTypes, 'cspace_data_config/record_types'
  autoload :RecordType, 'cspace_data_config/record_types'
  
  def self.safe_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end

end
