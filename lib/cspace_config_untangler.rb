# standard library
require 'csv'
require 'fileutils'
require 'json'
require 'logger'
require 'pp'
require 'yaml'

# external gems
require 'bundler/setup'
require 'dry-configurable'
require 'facets/kernel/blank'
require 'http'
require 'nokogiri'
require 'pry'
require 'ruby_jard'
require 'thor'


module CspaceConfigUntangler
  ::CCU = CspaceConfigUntangler
  module_function
  extend Dry::Configurable


  File.delete('log.log') if File::exist?('log.log')

  def logger
    @logger ||= Logger.new('log.log')
  end
  
  def app_dir
    File.realpath(File.join(File.dirname(__FILE__), '..'))
  end


  CCU.const_set('DATADIR', File.join(app_dir, 'data'))
  CCU.const_set('MAINPROFILE', 'core_6-1-0')
  CCU.const_set('CONFIGDIR', "#{CCU::DATADIR}/configs")
  config_file_names_deprecating = Dir.new(CCU::CONFIGDIR).children
    .reject{ |e| e['readable'] }
    .reject{ |e| e == '.keep' }
    .map{ |fn| File.basename(fn).sub('.json', '') }

  CCU.const_set('PROFILES', config_file_names_deprecating)

  CCU.const_set('LOG', Logger.new('log.log'))
  CCU.const_set('MAPPER_DIR', "#{CCU::DATADIR}/mappers")
  CCU.const_set('MAPPER_URI_BASE', 'https://raw.githubusercontent.com/collectionspace/cspace-config-untangler/main/data/mappers')

  default_datadir = File.join(app_dir, 'data')
  default_configdir = File.join(default_datadir, 'configs')
  default_templatedir = File.join(default_datadir, 'templates')
  default_mapperdir = File.join(default_datadir, 'mappers')
  


  setting :test, 'blah', reader: true
  setting :datadir, default_datadir, reader: true
  setting :configdir, default_configdir, reader: true
  setting :templatedir, default_templatedir, reader: true
  setting :mapperdir, default_mapperdir, reader: true

  config_file_names = Dir.new(default_configdir).children
    .reject{ |e| e['readable'] }
    .reject{ |e| e == '.keep' }
    .map{ |fn| File.basename(fn).sub('.json', '') }
  
  setting :profiles, config_file_names, reader: true
  setting :main_profile_name, 'core', reader: true
  setting :log, logger, reader: true
  setting :mapper_uri_base, 'https://raw.githubusercontent.com/collectionspace/cspace-config-untangler/main/data/mappers', reader: true

  def main_profile
    Pathname.new(CCU.configdir)
      .children(false)
      .select{ |filename| filename.to_s.start_with?(CCU.main_profile_name) }
      .map{ |filename| filename.to_s.delete_suffix(filename.extname) }
      .first
  end
  
  def safe_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end

  # Require all application files
  Dir.glob("#{__dir__}/cspace_config_untangler/**/*").sort.select{ |path| path.match?(/\.rb$/) }.each do |rbfile|
    require_relative rbfile.delete_prefix("#{File.expand_path(__dir__)}/").delete_suffix('.rb')
  end
end
