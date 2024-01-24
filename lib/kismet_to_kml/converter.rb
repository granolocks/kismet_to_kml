require "nokogiri"
require "optparse"

require_relative "consts"
require_relative "wifi_network"

module KismetToKml
  class Converter
    attr_accessor :gpsxml, :netxml, :wifi_networks, :kml_file

    def initialize(gpsxml_file, netxml_file, output_file)
      @kml_file = output_file
      @gpsxml = Nokogiri::XML(File.read(gpsxml_file))
      @netxml = Nokogiri::XML(File.read(netxml_file))
      @wifi_networks = {}
    end

    def convert!
      extract_networks
      extract_points
      generate_kml
    end

    private

    def extract_points
      gps_points = gpsxml.xpath("//gps-point").to_a.each do |point|
        next if useless_point(point)
        add_point(point)
      end
    end

    def useless_point(point)
      point.attributes[Consts::BSSID.downcase].value == Consts::GPSD_TRACKLOG_BSSID
    end

    def add_point(point)
      wifi_networks[point.attributes[Consts::BSSID.downcase].value]&.add_point(point)
    end

    def extract_networks
      netxml.xpath("//wireless-network").to_a.map do |node|
        next if node_has_useless_bssid(node)
        next if node_is_data_type(node)
        next if node_is_probe_response(node)
        next unless node_has_bssid(node)

        wifi_network = WifiNetwork.new(node)
        wifi_networks[wifi_network.bssid] = wifi_network

      end
    end

    def node_has_useless_bssid(node)
      node.children.search(Consts::BSSID).first.text == Consts::NULL_BSSID
    end

    def node_is_data_type(node)
      node.attributes[Consts::TYPE_ATTRIBUTE].value == Consts::DATA_TYPE
    end

    def node_is_probe_response(node)
      ssid = node
              .children
              .search(Consts::SSID)
              .search(Consts::TYPE_ATTRIBUTE)
              .first

      ssid && ssid.text == Consts::PROBE_RESPONSE
    end

    def node_has_bssid(node)
      node.search(Consts::BSSID).first
    end

    def generate_kml
      arbitrary_id = 0
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.kml(
          "xmlns" => "http://www.opengis.net/kml/2.2",
          "xmlns:gx" =>"http://www.google.com/kml/ext/2.2"
        ) do
          xml.Document(id: arbitrary_id) do
            arbitrary_id += 1
            wifi_networks.values.map do |net|
              xml.Placemark(id: arbitrary_id) do
                arbitrary_id += 1
                xml.name net.kml_name
                xml.Point(id: arbitrary_id) do
                  arbitrary_id += 1
                  xml.coordinates net.kml_placement
                end
              end
            end
          end
        end
      end

      File.write(kml_file, builder.to_xml)
    end
  end
end
