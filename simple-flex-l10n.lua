--
-- Simple filter script with localization (tag name_l10n_XX)
-- XX = tagret language (see below)
--
-- use "osm2pgsql -O flex -S flex-l10n.lua ..." for import

local osml10n = require "osml10n"

-- Target language
local lang = 'de'

-- Table name prefix
local prefix = 'planet_osm_hstore'

-- Used for splitting up long linestrings
if osm2pgsql.srid == 4326 then
    max_length = 1
else
    max_length = 100000
end

-- Ways with any of the following keys will be treated as polygon
local polygon_keys = {
    'aeroway',
    'amenity',
    'building',
    'harbour',
    'historic',
    'landuse',
    'leisure',
    'man_made',
    'military',
    'natural',
    'office',
    'place',
    'power',
    'public_transport',
    'shop',
    'sport',
    'tourism',
    'water',
    'waterway',
    'wetland',
    'abandoned:aeroway',
    'abandoned:amenity',
    'abandoned:building',
    'abandoned:landuse',
    'abandoned:power',
    'area:highway'
}

local delete_keys = {
    'attribution',
    'comment',
    'created_by',
    'fixme',
    'note',
    'note:*',
    'odbl',
    'odbl:note',
    'source',
    'source:*',
    'source_ref',

    -- Lots of import tags
    -- Corine (CLC) (Europe)
    'CLC:*',

    -- Geobase (CA)
    'geobase:*',
    -- CanVec (CA)
    'canvec:*',

    -- osak (DK)
    'osak:*',
    -- kms (DK)
    'kms:*',

    -- ngbe (ES)
    -- See also note:es and source:file above
    'ngbe:*',

    -- Friuli Venezia Giulia (IT)
    'it:fvg:*',

    -- KSJ2 (JA)
    -- See also note:ja and source_ref above
    'KSJ2:*',
    -- Yahoo/ALPS (JA)
    'yh:*',

    -- LINZ (NZ)
    'LINZ2OSM:*',
    'linz2osm:*',
    'LINZ:*',

    -- WroclawGIS (PL)
    'WroclawGIS:*',
    -- Naptan (UK)
    'naptan:*',

    -- TIGER (US)
    'tiger:*',
    -- GNIS (US)
    'gnis:*',
    -- National Hydrography Dataset (US)
    'NHD:*',
    'nhd:*',
    -- mvdgis (Montevideo, UY)
    'mvdgis:*',

    -- EUROSHA (Various countries)
    'project:eurosha_2012',

    -- UrbIS (Brussels, BE)
    'ref:UrbIS',

    -- NHN (CA)
    'accuracy:meters',
    'sub_sea:type',
    'waterway:type',
    -- StatsCan (CA)
    'statscan:rbuid',

    -- RUIAN (CZ)
    'ref:ruian:addr',
    'ref:ruian',
    'building:ruian:type',
    -- DIBAVOD (CZ)
    'dibavod:id',
    -- UIR-ADR (CZ)
    'uir_adr:ADRESA_KOD',

    -- GST (DK)
    'gst:feat_id',

    -- Maa-amet (EE)
    'maaamet:ETAK',
    -- FANTOIR (FR)
    'ref:FR:FANTOIR',

    -- 3dshapes (NL)
    '3dshapes:ggmodelk',
    -- AND (NL)
    'AND_nosr_r',

    -- OPPDATERIN (NO)
    'OPPDATERIN',
    -- Various imports (PL)
    'addr:city:simc',
    'addr:street:sym_ul',
    'building:usage:pl',
    'building:use:pl',
    -- TERYT (PL)
    'teryt:simc',

    -- RABA (SK)
    'raba:id',
    -- DCGIS (Washington DC, US)
    'dcgis:gis_id',
    -- Building Identification Number (New York, US)
    'nycdoitt:bin',
    -- Chicago Building Inport (US)
    'chicago:building_id',
    -- Louisville, Kentucky/Building Outlines Import (US)
    'lojic:bgnum',
    -- MassGIS (Massachusetts, US)
    'massgis:way_id',

    -- misc
    'import',
    'import_uuid',
    'OBJTYPE',
    'SK53_bulk:load'
}

function gen_columns(area, geometry_type)
    columns = {}

    local add_column = function (name, type)
        columns[#columns + 1] = { column = name, type = type }
    end

    add_column('z_order', 'int')

    if area ~= nil then
        if area then
            add_column('way_area', 'area')
        else
            add_column('way_area', 'real')
        end
    end

    add_column('tags', 'hstore')

    add_column('way', geometry_type)

    return columns
end

local tables = {}

tables.point = osm2pgsql.define_table{
    name = prefix .. '_point',
    ids = { type = 'node', id_column = 'osm_id' },
    columns = gen_columns(nil, 'point')
}

tables.line = osm2pgsql.define_table{
    name = prefix .. '_line',
    ids = { type = 'way', id_column = 'osm_id' },
    columns = gen_columns(false, 'linestring')
}

tables.polygon = osm2pgsql.define_table{
    name = prefix .. '_polygon',
    ids = { type = 'area', id_column = 'osm_id' },
    columns = gen_columns(true, 'geometry')
}

tables.roads = osm2pgsql.define_table{
    name = prefix .. '_roads',
    ids = { type = 'way', id_column = 'osm_id' },
    columns = gen_columns(false, 'linestring')
}

local z_order_lookup = {
    proposed = {1, false},
    construction = {2, false},
    steps = {10, false},
    cycleway = {10, false},
    bridleway = {10, false},
    footway = {10, false},
    path = {10, false},
    track = {11, false},
    service = {15, false},

    tertiary_link = {24, false},
    secondary_link = {25, true},
    primary_link = {27, true},
    trunk_link = {28, true},
    motorway_link = {29, true},

    raceway = {30, false},
    pedestrian = {31, false},
    living_street = {32, false},
    road = {33, false},
    unclassified = {33, false},
    residential = {33, false},
    tertiary = {34, false},
    secondary = {36, true},
    primary = {37, true},
    trunk = {38, true},
    motorway = {39, true}
}

function as_bool(value)
    return value == 'yes' or value == 'true' or value == '1'
end

function get_z_order(tags)
    local z_order = 100 * math.floor(tonumber(tags.layer or '0') or 0)
    local roads = false

    local highway = tags['highway']
    if highway then
        local r = z_order_lookup[highway] or {0, false}
        z_order = z_order + r[1]
        roads = r[2]
    end

    if tags.railway then
        z_order = z_order + 35
        roads = true
    end

    if tags.boundary and tags.boundary == 'administrative' then
        roads = true
    end

    if as_bool(tags.bridge) then
        z_order = z_order + 100
    end

    if as_bool(tags.tunnel) then
        z_order = z_order - 100
    end

    return z_order, roads
end

function make_check_in_list_func(list)
    local h = {}
    for _, k in ipairs(list) do
        h[k] = true
    end
    return function(tags)
        for k, _ in pairs(tags) do
            if h[k] then
                return true
            end
        end
        return false
    end
end

local is_polygon = make_check_in_list_func(polygon_keys)
local clean_tags = osm2pgsql.make_clean_tags_func(delete_keys)

function osm2pgsql.process_node(object)
    if clean_tags(object.tags) then
        return
    end
    
    if ((object.tags['name'] ~= nil) and (object.tags['name:' .. lang] ~= nil)) then
        object.tags['name_l10n_' .. lang] = osml10n.get_placename_from_tags(object.tags, false, false, '\n', lang, object.get_bbox)
    end

    tables.point:add_row({tags = object.tags})
end

function osm2pgsql.process_way(object)
    if clean_tags(object.tags) then
        return
    end
    
    local add_area = false
    if object.tags.natural == 'coastline' then
      object.tags.natural = nil
    end
    
    local output = {}

    local polygon
    local area_tag = object.tags.area
    if area_tag == 'yes' or area_tag == '1' or area_tag == 'true' then
        polygon = true
    elseif area_tag == 'no' or area_tag == '0' or area_tag == 'false' then
        polygon = false
    else
        polygon = is_polygon(object.tags)
    end

    if add_area then
        output.area = 'yes'
        polygon = true
    end

    local z_order, roads = get_z_order(object.tags)
    output.z_order = z_order

    if polygon and object.is_closed then
        if ((object.tags['name'] ~= nil) or (object.tags['name:' .. lang] ~= nil)) then
            object.tags['name_l10n_' .. lang] = osml10n.get_placename_from_tags(object.tags, false, false, '\n', lang, object.get_bbox)
        end
        output.tags = object.tags
        output.way = { create = 'area' }
        tables.polygon:add_row(output)
    else
        if ((object.tags['name'] ~= nil) or (object.tags['name:' .. lang] ~= nil)) then
            if (object.tags['highway'] ~= nil) then
                object.tags['name_l10n_' .. lang] = osml10n.get_streetname_from_tags(object.tags, true, false, '\n', lang, object.get_bbox)
            else
                object.tags['name_l10n_' .. lang] = osml10n.get_placename_from_tags(object.tags, false, false, '\n', lang, object.get_bbox)
            end
        end
        output.tags = object.tags
        output.way = { create = 'line', split_at = max_length }
        tables.line:add_row(output)
        if roads then
            tables.roads:add_row(output)
        end
    end
end

function osm2pgsql.process_relation(object)
    if clean_tags(object.tags) then
        return
    end

    local type = object.tags.type
    if (type ~= 'multipolygon') and (type ~= 'boundary') then
        return
    end
    object.tags.type = nil
    
    if ((object.tags['name'] ~= nil) and (object.tags['name:' .. lang] ~= nil)) then
        object.tags['name_l10n_' .. lang] = osml10n.get_placename_from_tags(object.tags, false, false, '\n', lang, object.get_bbox)
    end
    
    local output = {}

    local make_boundary = false
    local make_polygon = false
    if type == 'boundary' then
        make_boundary = true
    elseif type == 'multipolygon' and object.tags.boundary then
        make_boundary = true
    elseif type == 'multipolygon' then
        make_polygon = true
    end

    local z_order, roads = get_z_order(object.tags)
    output.z_order = z_order

    output.tags = object.tags

    if not make_polygon then
        output.way = { create = 'line', split_at = max_length }
        tables.line:add_row(output)
        if roads then
            tables.roads:add_row(output)
        end
    end

    if make_boundary or make_polygon then
        output.way = { create = 'area', multi = multi_geometry }
        tables.polygon:add_row(output)
    end
end
