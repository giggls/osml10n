local osml10n = {}

-- Returns the Levenshtein distance between the two given strings
function string.levenshtein(str1, str2)
  local len1 = string.len(str1)
  local len2 = string.len(str2)
  local matrix = {}
  local cost = 0

  -- quick cut-offs to save time
  if (len1 == 0) then
    return len2
  elseif (len2 == 0) then
    return len1
  elseif (str1 == str2) then
    return 0
  end

  -- initialise the base matrix values
  for i = 0, len1, 1 do
    matrix[i] = {}
    matrix[i][0] = i
  end
  for j = 0, len2, 1 do
    matrix[0][j] = j
  end

  -- actual Levenshtein algorithm
  for i = 1, len1, 1 do
    for j = 1, len2, 1 do
      if (str1:byte(i) == str2:byte(j)) then
        cost = 0
      else
        cost = 1
      end
        matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
      end
  end

  -- return the last value - this is the Levenshtein distance
  return matrix[len1][len2]
end

function osml10n.get_country_name(tags, targetlang, append)
  local count = 0
  local ldistmin = 1
  local ldistall
  local ldist
  local names = {}
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
      -- make sure that ldistall is always bigger than ldistmin by default
      ldistall=ldistmin + 1
      for _,name in ipairs(names) do
        ldist=string.levenshtein(name,tags["name:" .. v])
        if (ldistall > ldist) then
          ldistall=ldist;
        end
      end
      if (ldistall > ldistmin) then
        dbgprint("appending " .. tags["name:" .. v])
        table.insert(names,tags["name:" .. v])
      else
        dbgprint("ignoring  " .. tags["name:" .. v])
      end
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
