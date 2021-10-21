# frozen_string_literal: true

module CspaceConfigUntangler
  # Mixin module to determine the column naming style to use in CSV templates and JSON record mappers.
  #
  # Background: with the release of CS 7.0, all column names are consistently created, even if this
  #   makes some of them seeming unnecessarily long or redundant.
  module ColumnNameStylable
    def column_name_style(profile_name, profile_version)
      if column_style_configured?(profile_name)
        lookup_style(profile_name, profile_version)
      else
        handle_unconfigured_column_style(profile_name)
      end
    end

    def default_column_style
      :consistent
    end

    def handle_unconfigured_column_style(name)
      message = "Configure last fancy column version for #{name}. Defaulting to #{default_column_style} column style."
      CCU.log.warn(message)
      puts "WARNING: #{message}"
      default_column_style
    end
    
    def lookup_style(name, version)
      if version > CCU.last_fancy_column_versions[name]
        :consistent
      else
        :fancy
      end
    end

    def column_style_configured?(name)
      CCU.last_fancy_column_versions.key?(name)
    end
  end
end
