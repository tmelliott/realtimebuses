# Serve up data for the displays

## GTFS static data prep:

1. Check for updates each morning 
2. Up update, insert into sqlite3 database ...
3. Determine stop regions (north, west, etc)

## Process real-time data

1. Download real-time data
2. Determine distribution of delays (<-5, -5 -- -1, -1 -- 5, 5 -- 10, 10 -- 20, 20 -- 30, 30+)
3. Breakdown above by regions
4. Update timeseries of day's trace
5. Combine vehicle locations + trip updates (to colour points on map)
6. Write all to pb, save on Desktop


## Notes

- create a before/after script that loads/saves data into the correct location (which depends on where the application is running)
