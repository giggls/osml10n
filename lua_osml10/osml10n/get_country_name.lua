local osml10n = {}

function osml10n.get_country_name(tags, targetlang, append)
  local count = 0
  names = {}
  -- append name in target language
  if (append ~= true) then
    table.insert(names,tags["name:" .. targetlang])
  end
  -- table for country/language mapping
  langs = require "osml10n.country_languages"
  -- generate an array of all official country names
  languages = langs[string.lower(tags["ISO3166-1:alpha2"])]
  for k,v in pairs(languages) do
    if (tags["name:" .. v] ~= tags["name:" .. targetlang]) then
      table.insert(names,tags["name:" .. v])
      count = count + 1
    end
  end
  if count == 0 then
    table.insert(names,"")
  end
  if append then
    table.insert(names,tags["name:" .. targetlang])
  end
  
  return names
end

return osml10n
