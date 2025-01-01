local osm2pgsql = {}

osm2pgsql.OSMObject = {}
osm2pgsql.OSMObject.__index = osm2pgsql.OSMObject

function osm2pgsql.OSMObject:new(name, id, bbox)
  local self = setmetatable({}, osm2pgsql.OSMObject)
  self.name = name or "Unknown"
  self.id = id or 0
  self.bbox = bbox or { 0, 0, 0, 0 }
  return self
end

function osm2pgsql.OSMObject:info()
  return "OSMObject: " .. self.name .. " (ID: " .. self.id .. ")"
end

function osm2pgsql.OSMObject:get_bbox()
  return self.bbox[1], self.bbox[2], self.bbox[3], self.bbox[4]
end

function osm2pgsql.OSMObject:__tostring()
  return "osm2pgsql.OSMObject: " .. self.name .. " (ID: " .. self.id .. ")"
end

return osm2pgsql
