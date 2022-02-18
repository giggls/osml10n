local osml10n = {}

local rex = require "rex_pcre"

-- all available abbrev functions
local abbrev_func_all = {}

-- replaces some common parts of German street names with their abbreviation
abbrev_func_all.de = function(longname)
  local abbrev = longname
  local pos = string.find(abbrev,'traße')
  if ((pos ~= nil) and (pos >2)) then
    abbrev = string.gsub(abbrev,"Straße%s", "Str. ")
    abbrev = string.gsub(abbrev,"Straße$", "Str.")
    abbrev = string.gsub(abbrev,"straße%s", "str. ")
    abbrev = string.gsub(abbrev,"straße$", "str.")
  end
  pos = string.find(abbrev,'asse')
  if ((pos ~= nil) and (pos >2)) then
    abbrev = string.gsub(abbrev,"Strasse%s", "Str. ")
    abbrev = string.gsub(abbrev,"Strasse$", "Str.")
    abbrev = string.gsub(abbrev,"strasse%s", "str. ")
    abbrev = string.gsub(abbrev,"strasse$", "str.")
    abbrev = string.gsub(abbrev,"Gasse%s", "G. ")
    abbrev = string.gsub(abbrev,"Gasse$", "G.")
    abbrev = string.gsub(abbrev,"gasse%s", "g. ")
    abbrev = string.gsub(abbrev,"gasse$", "g.")
  end
  pos = string.find(abbrev,'latz')
  if ((pos ~= nil) and (pos >2)) then
    abbrev = string.gsub(abbrev,"Platz%s", "Pl. ")
    abbrev = string.gsub(abbrev,"Platz$", "Pl.")
    abbrev = string.gsub(abbrev,"platz%s", "pl. ")
    abbrev = string.gsub(abbrev,"platz$", "pl.")
  end
  pos = string.find(abbrev,'Professor')
  if ((pos ~= nil) and (pos >0)) then
    abbrev = string.gsub(abbrev,"Professor%s", "Prof. ")
    abbrev = string.gsub(abbrev,"Professor%-", "Prof.-")
  end
  pos = string.find(abbrev,'Doktor')
  if ((pos ~= nil) and (pos >0)) then
    abbrev = string.gsub(abbrev,"Doktor%s", "Dr. ")
    abbrev = string.gsub(abbrev,"Doktor%-", "Dr.-")
  end
  pos = string.find(abbrev,'Bürgermeister')
  if ((pos ~= nil) and (pos >0)) then
    abbrev = string.gsub(abbrev,"Bürgermeister%s", "Bgm. ")
    abbrev = string.gsub(abbrev,"Bürgermeister%-", "Bgm.-")
  end
  pos = string.find(abbrev,'Sankt')
  if ((pos ~= nil) and (pos >0)) then
    abbrev = string.gsub(abbrev,"Sankt%s", "St. ")
    abbrev = string.gsub(abbrev,"Sankt%-", "St.-")
  end
  return abbrev
end

-- replaces some common parts of English street names with their abbreviation
abbrev_func_all.en = function(longname)
  local abbrev = longname
  -- Avenue is a special case because we must try to exclude french names
  local pos = string.find(abbrev,'Avenue')
  if ((pos ~= nil) and (pos >1)) then
     if rex.match(abbrev, '^1[eè]?re Avenue\\b') == nil then
       if rex.match(abbrev, '^[0-9]+e Avenue\\b') == nil then
         abbrev=rex.gsub(abbrev,'(?!^)Avenue\\b','Ave.');
       end
     end
  end
  pos = string.find(abbrev,'Boulevard')
  if ((pos ~= nil) and (pos >1)) then
    abbrev=rex.gsub(abbrev,'(?!^)Boulevard\\b','Blvd.');
  end

  match = rex.match(abbrev, '(Crescent|Court|Drive|Lane|Place|Road|Street|Square|Expressway|Freeway)\\b')
  if (match ~= nil) then
    if (match == 'Crescent') then abbrev = string.gsub(abbrev,'Crescent','Cres.') end
    if (match == 'Court') then abbrev = string.gsub(abbrev,'Court','Ct') end
    if (match == 'Drive') then abbrev = string.gsub(abbrev,'Drive','Dr.') end
    if (match == 'Lane') then abbrev = string.gsub(abbrev,'Lane','') end
    if (match == 'Place') then abbrev = string.gsub(abbrev,'Place','Pl.') end
    if (match == 'Road') then abbrev = string.gsub(abbrev,'Road','Rd.') end
    if (match == 'Street') then abbrev = string.gsub(abbrev,'Street','St.') end
    if (match == 'Square') then abbrev = string.gsub(abbrev,'Square','Sq.') end

    if (match == 'Expressway') then abbrev = string.gsub(abbrev,'Expressway','Expy') end
    if (match == 'Freeway') then abbrev = string.gsub(abbrev,'Freeway','Fwy') end
  end

  -- Parkway Drive should be Parkway Dr. not "Pkwy Dr."
  pos = string.find(abbrev,'Parkway')
  if ((pos ~= nil) and (pos >1)) then
    abbrev = rex.gsub(abbrev,"Parkway\\b", "Pkwy")
  end

  match = rex.match(abbrev, '(North|South|West|East|Northwest|Northeast|Southwest|Southeast)\\b')
  if (match ~= nil) then
    if (match == 'North') then abbrev = string.gsub(abbrev,'North','N') end
    if (match == 'South') then abbrev = string.gsub(abbrev,'South','S') end
    if (match == 'West') then abbrev = string.gsub(abbrev,'West','W') end
    if (match == 'East') then abbrev = string.gsub(abbrev,'East','E') end
    if (match == 'Northwest') then abbrev = string.gsub(abbrev,'Northwest','NW') end
    if (match == 'Northeast') then abbrev = string.gsub(abbrev,'Northeast','NE') end
    if (match == 'Southwest') then abbrev = string.gsub(abbrev,'Southwest','SW') end
    if (match == 'Southeast') then abbrev = string.gsub(abbrev,'Southeast','SE') end
  end

  return abbrev
end

-- replaces some common parts of French street names with their abbreviation
abbrev_func_all.fr = function(longname)
  local abbrev = longname
  -- These are also French names and Avenue is not at the beginning of the Name
  -- those apear in French speaking parts of canada
  -- also Normalize ^1ere, ^1re, ^1e to 1re
  local pos = string.find(abbrev,'Avenue')
  if ((pos ~= nil) and (pos >1)) then
    abbrev = rex.gsub(abbrev, '^1([eè]?r?)e Avenue\\b','1re Av.')
    abbrev = rex.gsub(abbrev, '^([0-9]+)e Avenue\\b','%1e Av.')
  end

  match = rex.match(abbrev, '^(Avenue|Boulevard|Chemin|Esplanade|Impasse|Passage|Promenade|Route|Ruelle|Sentier)\\b')
  if (match ~= nil) then
    if (match == 'Avenue') then abbrev = string.gsub(abbrev,'Avenue','Av.') end
    if (match == 'Boulevard') then abbrev = string.gsub(abbrev,'Boulevard','Bd') end
    if (match == 'Chemin') then abbrev = string.gsub(abbrev,'Chemin','Ch.') end
    if (match == 'Esplanade') then abbrev = string.gsub(abbrev,'Esplanade','Espl.') end
    if (match == 'Impasse') then abbrev = string.gsub(abbrev,'Impasse','Imp.') end
    if (match == 'Passage') then abbrev = string.gsub(abbrev,'Passage','Pass.') end
    if (match == 'Promenade') then abbrev = string.gsub(abbrev,'Promenade','Prom.') end
    if (match == 'Route') then abbrev = string.gsub(abbrev,'Route','Rte') end
    if (match == 'Ruelle') then abbrev = string.gsub(abbrev,'Ruelle','Rle') end
    if (match == 'Sentier') then abbrev = string.gsub(abbrev,'Sentier','Sent.') end
  end

  return abbrev
end

-- replaces some common parts of Russion street names with their abbreviation
abbrev_func_all.ru = function(longname)
  local abbrev = longname
  abbrev = string.gsub(abbrev,'переулок', 'пер.')
  abbrev = string.gsub(abbrev,'тупик', 'туп.')
  abbrev = string.gsub(abbrev,'улица', 'ул.')
  abbrev = string.gsub(abbrev,'бульвар', 'бул.')
  abbrev = string.gsub(abbrev,'площадь', 'пл.')
  abbrev = string.gsub(abbrev,'проспект', 'просп.')
  abbrev = string.gsub(abbrev,'спуск', 'сп.')
  abbrev = string.gsub(abbrev,'набережная', 'наб.')
  return abbrev
end

-- replaces some common parts of Ukrainian street names with their abbreviation
abbrev_func_all.uk = function(longname)
  local abbrev = longname
  abbrev = string.gsub(abbrev,"провулок", "пров.")
  abbrev = string.gsub(abbrev,'тупик', 'туп.')
  abbrev = string.gsub(abbrev,'вулиця', 'вул.')
  abbrev = string.gsub(abbrev,'бульвар', 'бул.')
  abbrev = string.gsub(abbrev,'площа', 'пл.')
  abbrev = string.gsub(abbrev,'проспект', 'просп.')
  abbrev = string.gsub(abbrev,'спуск', 'сп.')
  abbrev = string.gsub(abbrev,'набережна', 'наб.')
  return abbrev
end

-- do street name abbreviation for specific language
function osml10n.street_abbrev(longname, langcode)
  if (abbrev_func_all[langcode] == nil) then
    return(longname)
  end
  return abbrev_func_all[langcode](longname)
end

function osml10n.street_abbrev_latin(longname)
  local abbrev = longname
  abbrev = abbrev_func_all.en(abbrev)
  abbrev = abbrev_func_all.de(abbrev)
  abbrev = abbrev_func_all.fr(abbrev)
--  abbrev = abbrev_func_all.es(abbrev)
--  abbrev = abbrev_func_all.pt(abbrev)
  return abbrev
end

function osml10n.street_abbrev_non_latin(longname)
  local abbrev = longname
  abbrev = abbrev_func_all.ru(abbrev)
  abbrev = abbrev_func_all.uk(abbrev)
  return abbrev
end

function osml10n.street_abbrev_all(longname)
  local abbrev = longname
  abbrev = osml10n.street_abbrev_latin(abbrev)
  abbrev = osml10n.street_abbrev_non_latin(abbrev)
  return abbrev
end

return osml10n
