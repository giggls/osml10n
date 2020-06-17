local osml10n = {}

function osml10n.get_country_name(tags, targetlang)
  names = {}
  -- append name in target language
  table.insert(names,tags["name:" .. targetlang])
  -- table for country/language mapping
  langs = require "osml10n.country_languages"
  -- generate an array of all official country names
  languages = langs[string.lower(tags["ISO3166-1:alpha2"])]
  for k,v in pairs(languages) do
    if (v ~= targetlang) then
      table.insert(names,tags["name:" .. v])
    end
  end
  
  return names
end

return osml10n
