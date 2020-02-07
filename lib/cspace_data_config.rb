# standard library
require 'csv'
require 'json'
require 'pp'

# external gems
require 'thor'

module CspaceDataConfig
  ::CDC = CspaceDataConfig
  autoload :VERSION, 'cspace_data_config/version'
  autoload :CommandLine, 'cspace_data_config/command_line'

  autoload :FieldCompiler, 'cspace_data_config/field_compiler'
  autoload :FieldGetter, 'cspace_data_config/field_getter'
  autoload :FormFieldGetter, 'cspace_data_config/field_getter'
  autoload :Profile, 'cspace_data_config/profile'
  autoload :Extensions, 'cspace_data_config/extensions'
  autoload :RecordTypes, 'cspace_data_config/record_types'
  autoload :RecordType, 'cspace_data_config/record_types'
end
