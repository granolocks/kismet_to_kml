# coding: utf-8
require "pry"

lib_dir = File.expand_path("../lib", __FILE__)

$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require "kismet_to_kml/version"

Gem::Specification.new do |s|
  s.name          = "kismet_to_kml"
  s.version       = KismetToKml::VERSION
  s.license       = "MIT"
  s.summary       = "Convert Kismet GPS data to KML"
  s.description   = "Converter utility to convert Gpsxml and Netxml files produced by kismet to KML"
  s.author        = "Gabe Koss"
  s.email         = "gabe@vermont.dev"
  s.files         = Dir.glob("{bin,lib}/**/*")
  s.homepage      = "https://github.com/granolocks/kismet_to_kml"
  s.metadata      = { "source_code_uri" => "https://github.com/granolocks/kismet_to_kml" }
  s.require_paths = ["lib"]
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.add_runtime_dependency "nokogiri", "~> 1.14.0"
  s.add_runtime_dependency "optparse", "~> 0.3.1"
end
