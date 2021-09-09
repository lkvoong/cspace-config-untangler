# frozen_string_literal: true

module CspaceConfigUntangler
  # basic value object to represent an option list
  class OptionList
    attr_reader :name, :options
    def initialize(name, list_config)
      @name = name
      @options = list_config['values']
    end
  end
end
