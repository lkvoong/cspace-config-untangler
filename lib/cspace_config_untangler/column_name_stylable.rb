# frozen_string_literal: true

require 'cspace_config_untangler'

module CspaceConfigUntangler
  # Mixin module to determine the column naming style to use in CSV templates and JSON record mappers.
  #
  # Background: with the release of CS 7.0, all column names are consistently created, even if this
  #   makes some of them seeming unnecessarily long or redundant.
  module ColumnNameStylable
    # The last version of each profile that should get fancy column names created.
    #
    LAST_FANCY_VERSION = {
      'anthro' => '4-1-2',
      'bonsai' => '4-1-1',
      'botgarden' => '2-0-1',
      'core' => '6-1-0',
      'fcart' => '3-0-1',
      'herbarium' => '1-1-1',
      'lhmc' => '3-1-1',
      'materials' => '2-0-0',
      'ocma' => '6-1-0',
      'publicart' => '2-0-1'
    }

    def column_name_style(profile_name, profile_version)
      if profile_version > LAST_FANCY_VERSION[profile_name]
        :consistent
      else
        :fancy
      end
    end
  end
end
