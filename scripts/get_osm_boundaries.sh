#!/bin/bash
#
#  get_osm_boundaries.sh
#
#  This script gets some boundaries from OSM, cleans them up and converts them
#  to GeoJSON. The results will be in the current directory.
#

get_osm_boundary_by_id() {
    local name="$1"
    local id="$2"

    wget -O "$name.osm" "https://api.openstreetmap.org/api/0.6/relation/$id/full"

    osmium getid --remove-tags --add-referenced "$name.osm" "r$id" --output-format=opl \
        | sed -e "s/ T[^ ]\+ / Ttype=multipolygon,cc=$name /" >"$name.opl"

    osmium export --overwrite --output="$name.geojson" "$name.opl"

    rm "$name.osm" "$name.opl"
}

get_osm_boundary_by_id hk 913110  # Hongkong
get_osm_boundary_by_id jp 382313  # Japan
get_osm_boundary_by_id mo 1867188 # Macau
get_osm_boundary_by_id tw 449220  # Taiwan
get_osm_boundary_by_id th 2067731 # Thailand

