require_relative "kismet_to_kml/converter"

module KismetToKml
  def self.run!(gpsxml, netxml, output_path)
    converter = Converter.new( gpsxml, netxml, output_path)
    converter.convert!
  end
end
