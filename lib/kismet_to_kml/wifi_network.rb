require_relative "consts"

module KismetToKml
  class WifiNetwork
    def initialize(network_node)
      @network_node = network_node
      @gps_points = []
    end

    def add_point(gps_point_node)
      @gps_points << gps_point_node.attributes.values.map do |attr|
        [
          attr.name.gsub("-", "_").to_sym,
          attr.value
        ]
      end.to_h
    end

    def bssid
      @network_node.search(Consts::BSSID).first.text
    end

    def ssid
      begin
        @network_node.search(Consts::SSID).first&.search(Consts::ESSID).first&.text || Consts::UNKNOWN_SSID
      rescue
        Consts::UNKNOWN_SSID
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

      [center_lon, center_lat, avg_alt].join(",")
    end
  end
end
