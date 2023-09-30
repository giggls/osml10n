local osml10n = {}

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
-- Mostly based on https://www.ponderweasel.com/whats-the-difference-between-an-ave-rd-st-ln-dr-way-pl-blvd-etc/
abbrev_func_all.en = function(longname)
  local abbrev = longname
  -- Avenue is a special case because we must try to exclude french names
  local pos = string.find(abbrev,'Avenue')
  if ((pos ~= nil) and (pos >1)) then
     if string.match(abbrev, '^1[eè]?re Avenue%f[%A]') == nil then
       if string.match(abbrev, '^[0-9]+e Avenue%f[%A]') == nil then
         -- simulate negative lookahead
         if not string.match(abbrev,'^Avenue') then
           abbrev=string.gsub(abbrev,'Avenue%f[%A]','Ave.');
         end
       end
     end
  end
  
  -- Do not shorten strings staring with Boulevard
  pos = string.find(abbrev,'Boulevard')
  if ((pos ~= nil) and (pos >1)) then
    abbrev=string.gsub(abbrev,'Boulevard%f[%A]','Blvd.');
  end

  -- Parkway Drive should be Parkway Dr. not "Pkwy Dr."
  pos = string.find(abbrev,'Parkway')
  if ((pos ~= nil) and (pos >1)) then
    abbrev = string.gsub(abbrev,"Parkway%f[%A]", "Pkwy.")
  end

  for _,obj in ipairs({
    {'Street%f[%A]','St.'},
    {'Road%f[%A]','Rd.'},
    {'Drive%f[%A]','Dr.'},
    {'Lane%f[%A]','Ln.'},
    {'Place%f[%A]','Pl.'},
    {'Square%f[%A]','Sq.'},
    {'Crescent%f[%A]','Cres.'},
    {'Court%f[%A]','Ct.'},
    {'Expressway%f[%A]','Expy.'},
    {'Freeway%f[%A]','Fwy.'}}) do
    local a = string.gsub(abbrev,obj[1], obj[2])
    if a ~= abbrev then
     abbrev = a
     break
    end
  end 

  for _,obj in ipairs({
    {'North%f[%A]','N'},
    {'South%f[%A]','S'},
    {'West%f[%A]','W'},
    {'East%f[%A]','E'},
    {'Nortwest%f[%A]','NW'},
    {'Northeast%f[%A]','NE'},
    {'Southwest%f[%A]','SW'},
    {'Southeast%f[%A]','SE'}}) do
    local a = string.gsub(abbrev,obj[1], obj[2])
    if a ~= abbrev then
     abbrev = a
     break
    end
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
    abbrev = string.gsub(abbrev, '^1([eè]?r?)e Avenue%f[%A]','1re Av.')
    abbrev = string.gsub(abbrev, '^([0-9]+)e Avenue%f[%A]','%1e Av.')
  end
  
  for _,obj in ipairs({
    {'^Avenue%f[%A]','Av.'},
    {'^Boulevard%f[%A]','Bd'},
    {'^Chemin%f[%A]','Ch.'},
    {'^Esplanade%f[%A]','Espl.'},
    {'^Impasse%f[%A]','Imp.'},
    {'^Passage%f[%A]','Pass.'},
    {'^Promenade%f[%A]','Prom.'},
    {'^Route%f[%A]','Rte'},
    {'^Ruelle%f[%A]','Rle'},
    {'^Sentier%f[%A]','Sent.'}}) do
    local a = string.gsub(abbrev,obj[1], obj[2])
    if a ~= abbrev then
     abbrev = a
     break
    end
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
