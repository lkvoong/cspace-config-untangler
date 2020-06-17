require 'cspace_config_untangler'

module CspaceConfigUntangler
    class CsvMapper
      ::CsvMapper = CspaceConfigUntangler::CsvMapper
      attr_reader :filename, :csv_options, :profile, :rectype, :rows, :mapper

      def initialize(filename:, csv_options: {}, profile:, rectype:)
        @filename = filename
        @csv_options = { headers: true }.merge(csv_options)
        @profile = profile
        @rectype = rectype
        @mapper = get_mapper
        @rows = get_rows
      end
      
      private

      def get_mapper
        p = CCU::Profile.new(@profile, rectypes: [@rectype], structured_date_treatment: :collapse)
        p.rectypes[0].mapping
      end

      def get_rows
        rows = CSV.read(@filename, **@csv_options)
        rows = rows.map{ |row| row.to_h }
        rowct = 1
        rows = rows.each do |row|
          row['rownumber'] = rowct
          rowct += 1
        end
        rows
      end
      
    end #class CsvMapper
end #module
