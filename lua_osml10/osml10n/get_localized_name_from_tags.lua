local unaccent = require "unaccent"

local osml10n = {}
local sabbrev = require "osml10n.street_abbrev"
local helpers = require "osml10n.helper_functions"
local transcript = require "osml10n.geo_transcript"
local rex = require "rex_pcre"

-- set to true to enable debug output of langage selection state machine 
local debugoutput = false

-- 5 most commonly spoken languages using latin script (hopefully)
local latin_langs = {"en","fr","es","pt","de"}

function dbgprint(msg)
  if debugoutput then
    print(msg)
  end
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
function osml10n.format_combined_name(names, show_brackets, separator)
  if (names[1] == '') then return names[2] end
  if (names[2] == '') then return names[1] end
  
  -- explicitely mark the whole string as LTR
  if (show_brackets) then
    return '‪' .. names[1] .. separator .. '(' .. names[2] .. ')' .. '‬'
  else
    return '‪' ..  names[1] ..  separator ..  names[2] ..  '‬'
   end
end

-- helper function "osml10n.gen_combined_names"
-- Will create a name+local_name pair as array of two strings
-- 
-- In case use_tags is true the combination might be re-created manually
-- from a name:xx tag using the requested separator instad of name
-- using a somewhat heuristic algorithm (see below)
-- 
-- NOTE: Variable local_name must contain the desired TAG (e.g. name:de) not the actual name string itself!
--
function osml10n.gen_combined_names(local_name, tags, localized_name_second, is_street, use_tags, non_latin)

  local resarr = {"",""}
  local unacc, unacc_local, unacc_tag
  local found, pos, nobrackets
  local idxl, idxn
  local n, ln
  local langcode
  local tag,v
  
  if (is_street == nil) then is_street = false end
  if (use_tags == nil) then use_tags = false end
  if (non_latin == nil) then non_latin = false end
  
  langcode = langcode_code_from_tag(local_name)
  
  -- index for inserting name and localized name
  if localized_name_second then
    idxl = 2 idxn = 1
  else
    idxl = 1 idxn = 2
  end
  local name = 'name'
  if (tags["name"] == nil) then
    if (is_street) then
      resarr[idxl]=sabbrev.street_abbrev(tags[local_name],langcode);
    else
      resarr[idxl]=tags[local_name]
    end
    return resarr
  end
  nobrackets=false
  -- Now we need to do some heuristic to check if the generation of a
  -- combined name is a good idea.
  
  -- Currently we do the following:
  -- If use_tags is false:
  -- If local_name is part of name as a single word, not just as a substring
  -- we return name and discard local_name.
  -- Otherwise we return a combined name with name and local_name
  -- 
  -- If use_tags is true:
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
  unacc_local = unaccent.unaccent(tags[local_name])
  found = false;
  pos = string.find(unacc,unacc_local:gsub("%W", "%%%1"))
  -- if string contains local_name
  if ( pos ~= nil) then
    if (rex.match(' ' .. unacc .. ' ', '[\\s\\(\\)\\-,;:/\\[\\]](\\Q' .. unacc_local .. '\\E)[\\s\\(\\)\\-,;:/\\[\\]]') ~= nil) then
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
      -- verbatim copy from old pl/pgsql code probably not needed
      if (tags == nil) then
        dbgprint("tags is nil ?!")
        nobrackets=true
      else
        for tag,v in pairs(tags) do
          -- ignore all the name:* tags here which are not languages here
          -- e.g. something like name:left name:right or romanized versions of the name
          if string.match(tag,'^name:[a-z][a-z][a-z]?$') then
            unacc_tag = unaccent.unaccent(v)
            if (unacc_tag ~= unacc_local) then
              if (rex.match(' ' .. unacc .. ' ','[\\s\\(\\)\\-,;:/\\[\\]](\\Q' .. unacc_tag .. '\\E)[\\s\\(\\)\\-,;:/\\[\\]]') ~= nil) then
                dbgprint('using ' .. tag .. ' (' .. v .. ') as second name');
                -- we found a 'second' name
                -- While a request might want to prefer printing this
                -- second name first anyway, to prefer on the ground
                -- language over l10n we pretend to know better in one 
                -- special case:
                   
                -- if the name in our target language is the first one in
                -- the generic name tag we will likely also want to print
                -- it first in l10n output.
                   
                -- This will make a lot of sense in bilingual areas where
                -- mappers usually use the convention of putting the more
                -- important language first in bilingual generic name tag.
                   
                -- So just remove the idxl and idxn assignments below
                -- if you want to get rid of this fuzzy behaviour!
                   
                -- Probably it might be a good idea to add an additional
                -- strict option to disable this behaviour.
                if (pos == 1) then
                  if (rex.match(string.sub(unacc,1,string.len(unacc_local)+1),'[\\s\\(\\)\\-,;:/\\[\\]]') ~= nil) then
                    dbgprint("swapping primary/second name")
                    idxl = 1;
                    idxn = 2;
                  end
                end
                name = tag;
                nobrackets=false;
                found=true;
                break
              else
                nobrackets=true; 
              end
            end
          end
        end
        if not found then
          if is_street then
            resarr[idxl] = sabbrev.street_abbrev_all(tags[local_name])
          else
            resarr[idxl] = tags[local_name]
          end
        return(resarr)
        end
      end
    end
  end
  print("pos=nil")
  if nobrackets then
    if is_street then
      resarr[idxn] = sabbrev.street_abbrev_all(tags[name])
    else
      resarr[idxn] = tags[local_name]
    end
  else
    if is_street then
      if (langcode ~= nil) then
        ln=sabbrev.street_abbrev(tags[local_name],langcode);
      else -- int_name case, we assume that this is in latin script
        ln=sabbrev.street_abbrev_latin(tags[local_name])
      end
      if (string.find(name,':') ~= nil) then
        n=sabbrev.street_abbrev(tags[name],langcode_code_from_tag(name));
      else
        if non_latin then
          n=sabbrev.street_abbrev_non_latin(tags[name]);
        else
          n=sabbrev.street_abbrev_all(tags[name]);
        end
      end
    else
      n=tags[name]
      ln=tags[local_name]
    end
    resarr[idxl] = ln
    resarr[idxn] = n
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

function osml10n.get_names_from_tags(id, tags, localized_name_second, is_street, targetlang, place)
  local resarr = {"",""}
  -- default is English now not German
  if (targetlang == nil) then targetlang = "en" end
  local target_tag = 'name:' .. targetlang
  if (tags[target_tag] ~= nil) then
    return osml10n.gen_combined_names(target_tag,tags,localized_name_second,is_street,true);
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
        return osml10n.gen_combined_names('int_name',tags,localized_name_second,is_street,false,true);
      end
    end
    -- if any latin language tag is available use it
    for _,lang in pairs(latin_langs) do
      -- we already checked for targetlang
      if (lang ~= targetlang) then
        target_tag = 'name:' .. lang
        if (tags[target_tag] ~= nil) then
          dbgprint("found roman language tag " .. lang)
          return osml10n.gen_combined_names(target_tag,tags,localized_name_second,is_street,true,true);
        end
      end
    end
    -- try to find a romanized version of the name
    -- this usually looks like name:ja_rm or  name:ko-Latn
    -- Just use the first tag of this kind found, because
    -- having more than one of them does not make sense
    for tag,_ in pairs(tags) do
      if (string.match(tag,'^name:.+_rm$') or string.match(tag,'^name:.+-Latn$')) then
        dbgprint( 'found romanization name tag ' .. tag)
        return osml10n.gen_combined_names(tag,tags,localized_name_second,is_street,true,true);
      end
    end
    if is_street then
      tags['name:Latn']=transcript.geo_transcript(id,sabbrev.street_abbrev_non_latin(tags['name']),place)
    else
      tags['name:Latn']=transcript.geo_transcript(id,tags['name'],place)
    end
      return osml10n.gen_combined_names('name:Latn',tags,localized_name_second,is_street,false,true);  
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
    for tag,_ in pairs(tags) do
      if (string.match(tag,'^name:.+_rm$') or string.match(tag,'^name:.+-Latn$')) then
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
function osml10n.get_streetname_from_tags(id, tags, localized_name_second, show_brackets, separator, targetlang, place)
  local names = {}
  if (show_brackets == nil) then show_brackets = false end
  if (separator == nil) then separator = ' - ' end
  
  names = osml10n.get_names_from_tags(id, tags, localized_name_second, true, targetlang, place)
  
  return(osml10n.format_combined_name(names,show_brackets,separator))
end

-- In lua targetlang and place are if not given in call,
-- so theses are kind of optional parameters
function osml10n.get_placename_from_tags(id, tags, localized_name_second, show_brackets, separator, targetlang, place)
  local names = {}
  if (show_brackets == nil) then show_brackets = false end
  if (separator == nil) then separator = '\n' end
  
  names = osml10n.get_names_from_tags(id, tags, localized_name_second, false, targetlang, place)

  return(osml10n.format_combined_name(names,show_brackets,separator))
end

return osml10n
