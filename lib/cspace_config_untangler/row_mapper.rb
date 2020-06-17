require 'cspace_config_untangler'

module CspaceConfigUntangler
  class RowMapper
    attr_reader :row, :mapper, :xml
    def initialize(row:, mapper:)
      @row = row
      @mapper = mapper
      @xml = build_xml
      #add_namespaces
    end

    private

    def build_xml
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.document {
          @mapper.keys.each do |ns|
            xml.send(ns){
              process_group(xml, [ns])
            }
          end
        }
      end
      builder.to_xml
    end

    def process_group(xml, grouppath)
      @mapper.dig(*grouppath).keys.each do |key|
        thispath = grouppath.clone.append(key)
        case key
        when :fieldmappings
          write_fields(xml, thispath)
        else
          xml.send(key){
            process_group(xml, thispath)
          }
        end
      end
    end
    
    def write_fields(xml, path)
      @mapper.dig(*path).each do |mapping|
        val = get_value(mapping.datacolumn)
        xml.send(mapping.fieldname, val) unless val.nil? || val.empty?
      end
    end

    def get_value(column)
      @row.fetch(column, nil)
    end
  end
end
