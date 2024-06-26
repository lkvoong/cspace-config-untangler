require_relative '../track_attributes'

module CspaceConfigUntangler
  module Forms
    class Field
      include CCU::TrackAttributes
      attr_reader :profile, :rectype, :name, :ns, :ns_for_id, :panel, :ui_path, :id, :to_csv

      def initialize(propsobj)
        @form = propsobj.form

        @profile = @form.rectype.profile.name
        @rectype = @form.rectype.name
        @name = propsobj.name
        @panel = propsobj.panel
        @ns = propsobj.ns
        @ns_for_id = propsobj.ns_for_id
        @ui_path = propsobj.ui_path
        @id = "#{@ns_for_id.sub('ns2:', '')}.#{@name}"
        @to_csv = format_csv
        clean_up
      end

      def csv_header
        return %w[profile record_type panel ui_path field_id field_name]
      end

      def to_h
        attrs = self.attr_readers.map{ |e| '@' + e.to_s }.map{ |e| e.to_sym }
        h = {}
        attrs.each{ |a| h[a] = self.instance_variable_get(a) }
        h.delete(:@to_csv)
        return h
      end

      private

      def format_csv
        arr = [@profile, @rectype]
        if @ui_path
          path = @ui_path.clone
          arr << path.shift
          arr << path.compact.join(' > ')
        else
          arr << ''
          arr << ''
        end
        @id ? arr << @id : arr << ''
        @name ? arr << @name : arr << ''
        return arr
      end

      def clean_up
        @form = @form.name
      end
    end
  end
end
