#!/bin/bash
#
# quick and dirty shell-script for converting the postgresql dump
# country_osm_grid.sql + Hong Kong and Macau boundaries to an sqlite database
# unfortunately this will currently need a postgresql database
#
# You need:
# * ogr2ogr
# * Running PostgreSQL/PostGIS with a database named after the local user with PostGIS enabled
# * Pyosmium (https://osmcode.org/pyosmium)
#

set -euo pipefail

output=country_osm_grid.db

echo -n -e "Downloading country_grid.sql.gz from nominatim.org... "
curl -s https://nominatim.org/data/country_grid.sql.gz |gzip -d >country_osm_grid.sql.in
echo "done."

echo -n -e "Downloading Hong Kong and Macau boundaries from OSM API... "
./hkmo2psql.py >hkmo.sql

head -n -3 country_osm_grid.sql.in > country_osm_grid.sql
cat hkmo.sql >> country_osm_grid.sql
tail -n 3 country_osm_grid.sql.in >> country_osm_grid.sql
echo "done."

echo -n -e "Importing to PostgreSQL... "
psql -f country_osm_grid.sql >/dev/null
echo -e "UPDATE country_osm_grid SET geometry=ST_SetSRID(geometry,4326);" |psql  >/dev/null
echo "done."

rm -f country_osm_grid.db
echo "Exporting into spatialite..."
ogr2ogr -progress -dsco SPATIALITE=YES -f "SQLITE" -gt 65536 $output PG: country_osm_grid

rm -f country_osm_grid.sql.in hkmo.sql

