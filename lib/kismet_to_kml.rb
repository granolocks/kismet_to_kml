require_relative "kismet_to_kml/converter"

module KismetToKml
  def self.run!(gpsxml, netxml, output_path)
    converter = KismetToKml::Converter.new( gpsxml, netxml, output)
    convert.convert!
  end
end
