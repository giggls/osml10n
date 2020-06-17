local osml10n = {}

-- helper function "is_latin"
-- checks if string consists of latin characters only
function osml10n.is_latin(text)
  for _, c in utf8.codes(text) do
    if (c > 591) then
      return false
    end
  end
  return true
end

-- helper function "contains_cjk"
-- checks if string contains CJK characters
-- 0x4e00-0x9FFF in unicode table
function osml10n.contains_cjk(text)
  for _, c in utf8.codes(text) do
    if (c > 0x4e00) and (c < 0x9FFF) then
      return true
    end
  end
  return false
end

-- helper function "contains_cyrillic"
-- checks if string contains Cyrillic characters
-- 0x0400-0x04FF in unicode table
function osml10n.contains_cyrillic(text)
  for _, c in utf8.codes(text) do
    if (c > 0x0400) and (c < 0x04ff) then
      return true
    end
  end
  return false
end

-- helper function "list2string"
-- Make a string from a list (a special form of a table in Lua)
function osml10n.list2string(list,delimiter)
  local string = ""
  for _,v in pairs(list) do
    string = string .. delimiter .. v
  end
  return string.sub(string,2,string.len(string))
end

return osml10n
