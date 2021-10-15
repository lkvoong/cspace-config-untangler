require_relative 'helpers'

module CspaceConfigUntangler
  module Cli
    class FieldsCli < Thor
      include CCU::Cli::Helpers

      desc 'csv', 'Write CSV containing full field data'
      option :output, desc: 'Path to output file', default: 'data/fields.csv', aliases: '-o'
      option :rectypes, desc: 'Comma separated list (no spaces) of record types to include. Defaults to all.', default: 'all', aliases: '-r'
      option :structured_date,
        desc: 'explode: report all individual structured date fields; collapse: report the parent of individual structured date fields as the field',
        default: 'explode',
        aliases: '-d'
      def csv
        unless %w[explode collapse].include?(options[:structured_date])
          puts '--structured_date parameter must be either "explode" or "collapse"'
          exit
        end
        rt = options[:rectypes] == 'all' ? [] : options[:rectypes].split(',')
        fields = []
        get_profiles.each {|profile|
          p = CCU::Profile.new(profile: profile, rectypes: rt, structured_date_treatment: options[:structured_date].to_sym)
          p.fields.each{ |f| fields << f }
        }
        unless fields.empty?
          CSV.open(options[:output], 'wb'){ |csv|
            csv << fields[0].csv_header
            fields.each{ |f| csv << f.to_csv }
          }
        end
      end

      desc 'nonunique', 'Print list of non-unique fields per profile'
      long_desc <<-LONGDESC
Uniqueness is determined by the full XML schema, i.e. the schema_path plus the field name.

The full schema_path should be unique within a record type. Non-unique fields are unexpected and the profile, record type, and schema path will be printed to the screen if any are found.
  LONGDESC
      def nonunique
        get_profiles.each {|profile|
          p = CCU::Profile.new(profile: profile)
          h = {}
          p.nonunique_fields.each{ |rt, fields| h[rt] = fields if fields.length > 0 }
          h.each{ |rt, fields| fields.each{ |f| puts "#{@name} - #{rt} - #{f}" } }
        }
      end

      desc 'unmappable', 'Prints list of fields per profile that are omitted from templates/mappers due to being unmappable'
      long_desc <<~DESC
This is introduced because some fields are being omitted from OMCA's templates/mappers because they have custom namespaces in their 'contact' subrecord. The Untangler assumes only the common namespace is used in subrecords, so these fields cannot be extracted/mapped at this point. 

An unmappable field is identified by its field_mapping object having nil data_type and xpath attributes.
      DESC
      option :rectypes, desc: 'Comma separated list (no spaces) of record types to include. Defaults to all.', default: 'all', aliases: '-r'
      option :structured_date,
        desc: 'explode: report all individual structured date fields; collapse: report the parent of individual structured date fields as the field',
        default: 'explode',
        aliases: '-d'
      def unmappable
        rt = options[:rectypes] == 'all' ? [] : options[:rectypes].split(',')
        get_profiles.each do |profile|
          profile_obj = CCU::Profile.new(
            profile: profile,
            rectypes: rt,
            structured_date_treatment: options[:structured_date].to_sym
          )
          profile_obj.rectypes.each{ |rt| rt.unmappable_fields }
        end
      end
    end
  end
end
