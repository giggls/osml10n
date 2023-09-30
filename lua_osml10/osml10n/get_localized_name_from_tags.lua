local unaccent = require "unaccent"

local osml10n = {}
local sabbrev = require "osml10n.street_abbrev"
local helpers = require "osml10n.helper_functions"
local transcript = require "osml10n.geo_transcript"

-- set to true to enable debug output of langage selection state machine 
local debugoutput = false

-- 5 most commonly spoken languages using latin script (hopefully)
local latin_langs = {"en","fr","es","pt","de"}

function dbgprint(msg)
  if debugoutput then
    io.stderr:write(msg .. '\n')
  end
end

-- create a propper "list" like object from a table with numbered keys
function dense_table(t)
  local indices = {}
  for i,_ in pairs(t) do
    table.insert(indices, i)
  end
  table.sort(indices)

  local dense_table = {}
  for _,i in pairs(indices) do
    table.insert(dense_table, t[i])
  end

  return dense_table
end

-- remove a given key from table
function table.removekey(table, key)
   local element = table[key]
   table[key] = nil
   return element
end

-- get country code from tag or nil in case of no country-code
function langcode_code_from_tag(tag)
  local s, langcode
  if (string.find(tag,':') == nil) then
    return nil
  else
    for s in string.gmatch(tag, '([^:]+)') do langcode = s end
    return langcode
  end
end

-- helper function "osml10n.format_combined_name"
-- Format an array of two strings into a formated string which can be rendered on the map
function osml10n.format_combined_name(names, separator)
  if (names[1] == '') then return names[2] end
  if (names[2] == '') then return names[1] end

   -- explicitely mark the whole string as LTR  
  local resultstr = '‪'
  first = true
  for k,n in ipairs(names) do
    if first then
      resultstr = resultstr .. n
      first = false
    else
      resultstr = resultstr .. separator .. n
    end
  end
  resultstr = resultstr .. '‬'
  return resultstr
end

-- helper function "osml10n.gen_combined_names"
-- Will create a names+local_name pair as array of two or more strings
-- 
-- NOTE: Variable local_name must contain the desired TAG (e.g. name:de) not the actual name string itself!
--
function osml10n.gen_combined_names(local_tag, tags, localized_name_last, is_street, non_latin)

  local resarr = {"",""}
  local unacc, unacc_local, unacc_tag
  local found, pos
  local idxl, idxn
  local n, ln
  local langcode
  local tag,v
  local additional_names={}
  local local_name
  
  if (is_street == nil) then is_street = false end
  if (non_latin == nil) then non_latin = false end
  
  langcode = langcode_code_from_tag(local_tag)
  local_name = tags[local_tag]

  -- this is a pseudo tag which is only used internally
  if (langcode == 'l10n_Latn') then
    -- table.remove(tags,'l10n_Latn')
    table.removekey(tags,local_tag)
  end
  
  -- index for inserting name and localized name
  if localized_name_last then
    idxl = 2 idxn = 1
  else
    idxl = 1 idxn = 2
  end
  local name = 'name'
  if (tags["name"] == nil) then
    if (is_street) then
      resarr[idxl]=sabbrev.street_abbrev(local_name,langcode);
    else
      resarr[idxl]=local_name
    end
    return resarr
  end
  -- Now we need to do some heuristic to check if the generation of a
  -- combined name is a good idea.
  
  -- Currently we do the following:
  --
  -- If local_name is part of name as a single word, not just as a substring
  -- we try to extract a second valid name (defined in "name:*" as a single word)
  -- from "name". If succeeeded we redefine name and also return a combined name.
  -- 
  -- This is useful in bilingual areas where name usually contains two langages.
  -- E.g.: name=>"Bolzano - Bozen", target language="de" would be rendered as:
  -- 
  -- Bozen
  -- Bolzano
  
  -- at this place tags["name"] is not nil
  if helpers.is_latin(tags['name']) then
    unacc = unaccent.unaccent(tags['name'])
  else
    unacc = tags['name']  
  end
  unacc_local = unaccent.unaccent(local_name)
  found = false;
  pos = string.find(unacc,unacc_local:gsub("%W", "%%%1"))

  -- replace lua magic characters,
  local escaped_unacc_local = string.gsub(unacc_local, '[.]', '::')
  escaped_unacc_local = string.gsub(escaped_unacc_local, '[][()%%+*?^$]', '@')

  -- ignore localized_name_last option if localized_name_last is specified but our localized
  -- name is on position 1 in generic name tag.
  pos=string.find(' ' .. unacc .. ' ', '[][%s()-,;:/]' .. escaped_unacc_local .. '[][%s()-,;:/]')
  if ((pos == 1) and localized_name_last)then
    dbgprint("forcing localized_name_last=false")
    localized_name_last=false
  end
  
  -- if string contains local_name
  if ( pos ~= nil) then
      -- try to create a better string for combined name than plain name
      -- do these complex checks only in case unaccented name != unaccented local_name
      if (string.len(unacc) == string.len(unacc_local)) then
        if is_street then
          resarr[idxn] = sabbrev.street_abbrev(tags[name],langcode)
        else
          resarr[idxn] = tags[name]
        end
        return(resarr)
      end
      
      -- find all additional names which are part of generic name tag and add them to
      -- a list of additional names in order of importance
      -- a lower position in "name" string means name is more important
      local tmp_names = {}
      local tpos = 0

      -- extract name:* tags which are languages and order them
      -- ignore anything else like name:left name:right or romanized versions of the name
      local lang_names = {}
      for tag,v in pairs(tags) do
        if string.match(tag,'^name:[a-z][a-z][a-z]?$') then
          table.insert(lang_names,tag)
        end
      end
      table.sort(lang_names)
      
      for _,tag in ipairs(lang_names) do
	unacc_tag = unaccent.unaccent(tags[tag])
	local escaped_unacc_tag = string.gsub(unacc_tag, '[.]', '::')
	escaped_unacc_tag = string.gsub(escaped_unacc_tag, '[][()%%+*?^$]', '@')
	if (unacc_tag ~= unacc_local) then
	  local utag_pos=string.find(' ' .. unacc .. ' ','[][%s()-,;:/]' .. escaped_unacc_tag .. '[][%s()-,;:/]')
	  if (utag_pos  ~= nil) then
	    tmp_names[utag_pos]=tag
	    dbgprint('found additional name ' .. tag .. ' (' .. tags[tag] .. ')');
	    found=true;
	  end
	end
      end
      additional_names = dense_table(tmp_names)
      
      if not found then
        if is_street then
          resarr[idxl] = sabbrev.street_abbrev_all(local_name)
        else
          resarr[idxl] = local_name
        end
      return(resarr)
      end
  end
  if additional_names[1] == nil then
    table.insert(additional_names, name)
  end

  resarr={}
  if is_street then
    if not localized_name_last then
      if (langcode ~= nil) then
        table.insert(resarr,sabbrev.street_abbrev(local_name,langcode))
      else
        table.insert(resarr,sabbrev.street_abbrev_latin(local_name))
      end
    end
    for _,v in ipairs(additional_names) do
      if (string.find(v,':') ~= nil) then
        table.insert(resarr,sabbrev.street_abbrev(tags[v],langcode_code_from_tag(v)))
      else
        if non_latin then
          table.insert(resarr,sabbrev.street_abbrev_non_latin(tags[v]))
        else
          table.insert(resarr,sabbrev.street_abbrev_all(tags[v]))
        end
      end
    end
    if localized_name_last then
      if (langcode ~= nil) then
        table.insert(resarr,sabbrev.street_abbrev(local_name,langcode))
      else
        table.insert(resarr,sabbrev.street_abbrev_latin(local_name))
      end
    end
  else
    if not localized_name_last then
      table.insert(resarr,local_name)
    end
    for _,v in ipairs(additional_names) do
      table.insert(resarr,tags[v])
    end
    if localized_name_last then
      table.insert(resarr,local_name)
    end
  end
  return(resarr)
end

-- Get name by looking at various name tags or transliteration as a last resort:

-- 1. name:<targetlang>
-- 2. name (if latin)
-- 3. int_name (if latin)
-- 5. name:en (if not targetlang)
-- 5. name:fr (if not targetlang)
-- 6. name:es (if not targetlang)
-- 7: name:pt (if not targetlang)
-- 8. name:de (if not targetlang)
-- 9. Any tag of the form name:<targetlang>_rm or name:<targetlang>-Latn

-- This scheme is used in functions:
-- osml10n.get_names_from_tags and osml10n.get_localized_name_from_tags
--
-- While the former returns two names in most cases the latter just returns one!

function osml10n.get_names_from_tags(id, tags, localized_name_last, is_street, targetlang, place)
  local resarr = {"",""}
  -- default is English now not German
  if (targetlang == nil) then targetlang = "en" end
  local target_tag = 'name:' .. targetlang
  if (tags[target_tag] ~= nil) then
    return osml10n.gen_combined_names(target_tag,tags,localized_name_last,is_street);
  end
  -- at this stage we have no name tagged in target language, but generic "name" tag might be in
  -- latin script or even in our target language, so, just use it
  if (tags['name'] ~= nil) then
    if helpers.is_latin(tags['name']) then
      if is_street then
        resarr[1] = sabbrev.street_abbrev_latin(tags['name']);
      else
        resarr[1] = tags['name'];
      end
      return resarr;
    end
    -- at this stage name is not latin so we need to have a look at alternatives
    -- these are currently int_name, common latin scripts and romanized version of the name
    if (tags['int_name'] ~= nil) then
      if helpers.is_latin(tags['int_name']) then
        return osml10n.gen_combined_names('int_name',tags,localized_name_last,is_street,true);
      end
    end
    -- if any latin language tag is available use it
    for _,lang in pairs(latin_langs) do
      -- we already checked for targetlang
      if (lang ~= targetlang) then
        target_tag = 'name:' .. lang
        if (tags[target_tag] ~= nil) then
          dbgprint("found roman language tag " .. lang)
          return osml10n.gen_combined_names(target_tag,tags,localized_name_last,is_street,true);
        end
      end
    end
    -- try to find a romanized version of the name
    -- this usually looks like name:ja_rm or  name:ko-Latn
    -- Just use the first tag of this kind found, because
    -- having more than one of them does not make sense
    for tag,_ in pairs(tags) do
      if (string.match(tag,'^name:[a-z][a-z][a-z]?_rm$') or string.match(tag,'^name:[a-z][a-z][a-z]?-Latn$')) then
        dbgprint( 'found romanization name tag ' .. tag)
        return osml10n.gen_combined_names(tag,tags,localized_name_last,is_street,true);
      end
    end
    if is_street then
      tags['name:l10n_Latn']=transcript.geo_transcript(id,sabbrev.street_abbrev_non_latin(tags['name']),place)
    else
      tags['name:l10n_Latn']=transcript.geo_transcript(id,tags['name'],place)
    end
      return osml10n.gen_combined_names('name:l10n_Latn',tags,localized_name_last,is_street);  
  else
    return resarr; 
  end
end

function osml10n.get_localized_name_from_tags(id, tags, targetlang, place)
  local resarr = {"",""}
  -- default is English now not German
  if (targetlang == nil) then targetlang = "en" end
  local target_tag = 'name:' .. targetlang
  if (tags[target_tag] ~= nil) then
    return tags[target_tag]
  end
  -- at this stage we have no name tagged in target language, but generic "name" tag might be in
  -- latin script or even in our target language, so, just use it
  if (tags['name'] ~= nil) then
    if helpers.is_latin(tags['name']) then
      return tags['name']
    end
    -- at this stage name is not latin so we need to have a look at alternatives
    -- these are currently int_name, common latin scripts and romanized version of the name
    if (tags['int_name'] ~= nil) then
      if helpers.is_latin(tags['int_name']) then
        return tags['int_name']
      end
    end

    -- if any latin language tag is available use it
    for _,lang in pairs(latin_langs) do
      -- we already checked for targetlang
      if (lang ~= targetlang) then
        target_tag = 'name:' .. lang
        if (tags[target_tag] ~= nil) then
          dbgprint("found roman language tag " .. lang)
          return tags[target_tag]
        end
      end
    end
    -- try to find a romanized version of the name
    -- this usually looks like name:ja_rm or  name:ko-Latn
    -- Just use the first tag of this kind found, because
    -- having more than one of them does not make sense
    -- make sure, that something like name:left:* does not match, as
    -- we can not support this
    for tag,_ in pairs(tags) do
      if (string.match(tag,'^name:[a-z][a-z][a-z]?_rm$') or string.match(tag,'^name:[a-z][a-z][a-z]?-Latn$')) then
        dbgprint( 'found romanization name tag ' .. tag)
        return tags[tag]
      end
    end
    -- do transliteration as a last resort
    return transcript.geo_transcript(id,tags['name'],place)
  else
    return ''
  end
end

-- In lua targetlang and place are if not given in call,
-- so theses are kind of optional parameters
function osml10n.get_streetname_from_tags(id, tags, localized_name_last, separator, targetlang, place)
  local names = {}
  if (separator == nil) then separator = ' - ' end
  
  names = osml10n.get_names_from_tags(id, tags, localized_name_last, true, targetlang, place)
  
  return(osml10n.format_combined_name(names,separator))
end

-- In lua targetlang and place are if not given in call,
-- so theses are kind of optional parameters
function osml10n.get_placename_from_tags(id, tags, localized_name_last, separator, targetlang, place)
  local names = {}
  if (separator == nil) then separator = '\n' end
  
  names = osml10n.get_names_from_tags(id, tags, localized_name_last, false, targetlang, place)

  return(osml10n.format_combined_name(names,separator))
end

return osml10n
