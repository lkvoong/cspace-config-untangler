# frozen_string_literal: true

require_relative 'hash_iterator'

module CspaceConfigUntangler
  module Fields
    module Definition
      class NamespaceFieldParser
        attr_reader :config
        # @param config [CCU::Fields::Definition::Config]
        def initialize(config)
          @config = config
          update_subrecord_field_hash
          HashIterator.new(@config, self.class)

          binding.pry
        end

#        private

        
        def subrecord_config_hash(subrec_type)
          @config.profile_config['recordTypes'][subrec_type]['fields']['document'][namespace]
        end
        
        def update_subrecord_field_hash
          @config.update_field_hash(subrecord_config_hash('contact')) if namespace.start_with?('ns2:contacts_')
          @config.update_field_hash(subrecord_config_hash('blob')) if namespace == ('ns2:blobs_common')
        end
        
        # # fdp = FieldDefinitionParser
        # attr_reader :fdp, :ns, :ns_for_id, :config

        # def initialize(fdpobj, ns, hash)
        #   @fdp = fdpobj
        #   @config.delete('[config]')

        #   @config.each{ |k, h|
        #     if h.keys.length == 1 && h.keys == ['[config]']
        #       Verifier.new(@fdp, k, h, self)
        #     elsif h.keys.length > 1
        #       Grouping.new(@fdp, k, h, self)
        #     else
        #       CCU::LOG.warn("FIELD DEFINITION STRUCTURE: #{@fdp.rectype.profile.name} - #{@fdp.rectype.name} - #{@ns} - has unexpected keys")
        #     end
        #   }
        # end
      end
    end
  end
end
