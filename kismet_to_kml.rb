require 'nokogiri'
require 'pry'
require 'optparse'

ESSID = "essid"
BSSID = "BSSID"
DATA_TYPE = "data"
GPSD_TRACKLOG_BSSID = "GP:SD:TR:AC:KL:OG"
NULL_BSSID = "00:00:00:00:00:00"
PROBE_RESPONSE = "Probe Response"
SSID = "SSID"
TYPE_ATTRIBUTE = "type"
UNKNOWN_SSID = "Unknown"

class WifiNetwork
  def initialize(network_node)
    @network_node = network_node
    @gps_points = []
  end

  def add_point(gps_point_node)
    @gps_points << gps_point_node.attributes.values.map do |attr|
      [
        attr.name.gsub('-', '_').to_sym,
        attr.value
      ]
    end.to_h
  end

  def bssid
    @network_node.search(BSSID).first.text
  end

  def ssid
    begin
      @network_node.search(SSID).first&.search(ESSID).first&.text || UNKNOWN_SSID
    rescue
      UNKNOWN_SSID
    end
  end

  def kml_name
    "#{ssid} (#{bssid})"
  end

  def kml_placement
    total_weight = 0
    lat_sum = 0
    lon_sum = 0
    alt_sum = 0

    @gps_points.each do |point|
      lat = point[:lat].to_f
      lon = point[:lon].to_f
      dbm = point[:signal_dbm].to_i
      alt = point[:alt].to_f
      weight = 10 ** ( dbm / 10 )

      lat_sum += lat * weight
      lon_sum += lon * weight
      alt_sum += alt

      total_weight += weight
    end

    center_lat = (lat_sum / total_weight).round(6)
    center_lon = (lon_sum / total_weight).round(6)
    avg_alt = (alt_sum / @gps_points.count).round(3)

    [center_lon, center_lat, avg_alt].join(',')
  end
end

class KismetToKml
  attr_accessor :gpsxml, :netxml, :wifi_networks, :kml_file

  def initialize(gpsxml_file, netxml_file, output_file)
    @kml_file = output_file
    @gpsxml = Nokogiri::XML(File.read(gpsxml_file))
    @netxml = Nokogiri::XML(File.read(netxml_file))
    @wifi_networks = {}
  end

  def extract_points
    gps_points = gpsxml.xpath('//gps-point').to_a.each do |point|
      next if point.attributes[BSSID.downcase].value == GPSD_TRACKLOG_BSSID
      wifi_networks[point.attributes[BSSID.downcase].value]&.add_point(point)
    end
  end

  def extract_networks
    netxml.xpath('//wireless-network').to_a.map do |node|
      # TODO add comment explaining these
      if node.children.search(BSSID).first.text == NULL_BSSID
        next
      elsif node.attributes[TYPE_ATTRIBUTE].value == DATA_TYPE
        next
      elsif node.children.search(SSID).search(TYPE_ATTRIBUTE).first&.text == PROBE_RESPONSE
        next
      elsif !node.search(BSSID).first
        next
      else
        wifi_network = WifiNetwork.new(node)
        wifi_networks[wifi_network.bssid] = wifi_network
      end
    end
  end

  def generate_kml
    arbitrary_id = 0
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
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

options = {}
option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby kismet_to_kml.rb [options]"

  opts.on("-n", "--netxml NETXML", "Netxml file (required)") do |v|
    options[:netxml] = v
  end

  opts.on("-g", "--gpsxml GPSXML", "Gpsxml file (required)") do |v|
    options[:gpsxml] = v
  end

  opts.on("-o", "--output OUTPUT", "Output kml file (required)") do |v|
    options[:output] = v
  end
end
option_parser.parse!

if !(options[:netxml] && options[:gpsxml] && options[:output])
  puts option_parser.help
  exit 1
else
  k2k = KismetToKml.new(options[:gpsxml], options[:netxml], options[:output])
  k2k.extract_networks
  k2k.extract_points
  k2k.generate_kml
end


