There are other tools that do this including the `kismetdb_to_kml` script that
is part of
[`kismet-logtools`](https://www.kismetwireless.net/docs/readme/kismetdb/kismetdb_kml/).
That being said, I wanted to do my own thing and needed a place to put it so
here we are. 

```
Usage: ruby kismet_to_kml.rb [options]
  -n, --netxml NETXML              Netxml file (required)
  -g, --gpsxml GPSXML              Gpsxml file (required)
  -o, --output OUTPUT              Output kml file (required)
```
