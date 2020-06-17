#!/usr/bin/lua
--
-- run unit tests for osml10n functions
--

osml10n = require("osml10n")
unaccent = require("unaccent")

-- Wtf? I really think that a simple tostring method as in python should be part of any data-type
function hash2string(hash)
  local string = "{ "
  for k,v in pairs(hash) do
    if (type(k) == "number") then
      if (type(v) == "number") then
        string = string .. v .. ', '
      else
        string = string .. '"' .. v .. '", '
      end
    else
      if (type(v) == "number") then
        string = string .. '["' .. k .. '"] = ' .. v .. ', '
      else
        string = string .. '["' .. k .. '"] = "' .. v .. '", '
      end
    end
  end
  string = string.sub(string,1,string.len(string)-2)
  string = string .. " }"
  return string
end

function x2string(x)
  if (type(x) == "table") then
    ret = hash2string(x)
  else
    ret = '"' .. tostring(x) .. '"'
  end
  return ret
end

-- found on the web :(
function table_compare(t1,t2)
  local ty1 = type(t1)
  local ty2 = type(t2)
  if ty1 ~= ty2 then return false end
  -- non-table types can be directly compared
  if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
  -- as well as tables which have the metamethod __eq
  for k1,v1 in pairs(t1) do
  local v2 = t2[k1]
  if v2 == nil or not table_compare(v1,v2) then return false end
  end
  for k2,v2 in pairs(t2) do
  local v1 = t1[k2]
  if v1 == nil or not table_compare(v1,v2) then return false end
  end
  return true
end

-- maximum number of function arguments ist currently 2
function checkoutput(func,name,result,...)

  local msg = "calling osml10n." .. name .. '('

  for _,v in ipairs({...}) do
    msg = msg .. x2string(v) .. ", "
  end
  msg = string.sub(msg, 0, #msg-2) .. '):'
  print(msg)
  
  res=func(...)

  if (type(res) == "table") then
    if table_compare(res,result) then
      print("[\27[1;32mOK\27[0;0m] (expected \27[1;1m" .. hash2string(result) .. "\27[1;0m, got \27[1;1m" .. hash2string(res) .. "\27[1;0m)")
      passed = passed + 1
    else
      print("[\27[1;31mERROR\27[0;0m] (expected \27[1;1m" .. hash2string(result) .. "\27[1;0m, got \27[1;1m" .. hash2string(res) .. "\27[1;0m)")
      failed = failed + 1
    end
  else
    if (res == result) then
      print("[\27[1;32mOK\27[0;0m] (expected \27[1;1m" .. tostring(result) .. "\27[1;0m, got \27[1;1m" .. tostring(res) .. "\27[1;0m)")
      passed = passed + 1
    else
      print("[\27[1;31mERROR\27[0;0m] (expected \27[1;1m" .. tostring(result) .. "\27[1;0m, got \27[1;1m" .. tostring(res) .. "\27[1;0m)")
      failed = failed + 1
    end
  end
end

passed = 0
failed = 0

-- function unit tests
-- unaccent function via C-Interface
checkoutput(unaccent.unaccent,"unaccent","Besancon","Besançon")
checkoutput(unaccent.unaccent,"unaccent","Munchen","München")
checkoutput(unaccent.unaccent,"unaccent","Brussel","Brüssel")
print("")
checkoutput(osml10n.is_latin,"is_latin",true,"Eigenheimstraße")
checkoutput(osml10n.is_latin,"is_latin",false,"улица Воздвиженка")
print("")
checkoutput(osml10n.contains_cjk,"contains_cjk",false,"Eigenheimstraße")
checkoutput(osml10n.contains_cjk,"contains_cjk",true,"100 漢字")
print("")
checkoutput(osml10n.contains_cyrillic,"contains_cyrillic",false,"Eigenheimstraße")
checkoutput(osml10n.contains_cyrillic,"contains_cyrillic",true,"улица Воздвиженка")
print("")
checkoutput(osml10n.list2string,"list2string","Indien|भारत|India",{ "Indien", "भारत", "India" },'|')
print("")
checkoutput(osml10n.get_country_name,"get_country_name",{ "Indien", "भारत", "India" } , {["ISO3166-1:alpha2"]= "IN", ["name:de"] = "Indien", ["name:hi"] = "भारत", ["name:en"] = "India"}, "de")
checkoutput(osml10n.get_country_name,"get_country_name",{ "India", "भारत" } , {["ISO3166-1:alpha2"]= "IN", ["name:de"] = "Indien", ["name:hi"] = "भारत", ["name:en"] = "India"}, "en")
print("")

for _, lang in pairs({"de", "en", "fr"}) do
  -- streetname abbreviations for current language
  for line in io.lines(lang .. "_tests.csv") do
    local t = {}
    for word in string.gmatch(line, '([^,]+)') do
      table.insert(t,word)
    end
    checkoutput(osml10n.street_abbrev,"street_abbrev",t[2],t[1],lang)
  end
  print("")
end

-- geo_transcript function via extrnal daemon

-- Japan
checkoutput(osml10n.geo_transcript,"geo_transcript","Toukyou","東京",{ 138.79, 36.08, 139.51, 36.77 })

-- China
checkoutput(osml10n.geo_transcript,"geo_transcript","dōng jīng","東京",{113.05, 29.45, 115.73, 32.13})

-- Thailand
checkoutput(osml10n.geo_transcript,"geo_transcript","hongsamut prachachon",'ห้องสมุดประชาชน',{100, 14, 101, 15})

-- Macau
checkoutput(osml10n.geo_transcript,"geo_transcript","hōeng góng","香港",{113.54, 22.16, 113.58, 22.2})

-- Hongkong
checkoutput(osml10n.geo_transcript,"geo_transcript","hōeng góng","香港",{114.15, 22.28, 114.2, 22.33})

print("")

checkoutput(osml10n.get_placename_from_tags,"get_placename_from_tags", "‪Москва́ - Moskau‬",{ ["name"] = "Москва́", ["name:de"] = "Moskau", ["name:en"] = "Moscow" },true,false, ' - ','de')
checkoutput(osml10n.get_placename_from_tags,"get_placename_from_tags","‪Moskau|Москва́‬",{ ["name"] = "Москва́", ["name:de"] = "Moskau", ["name:en"] = "Moscow" },false,false, '|','de')

-- in lua rewriute default is 'en' for language
checkoutput(osml10n.get_placename_from_tags,"get_placename_from_tags", "‪Cairo|القاهرة‬", { ["name"] = "القاهرة", ["name:de"] = "Kairo", ["int_name"] = "Cairo", ["name:en"] = "Cairo" },false,false, '|')

checkoutput(osml10n.get_placename_from_tags,"get_placename_from_tags", "‪Brüssel|Bruxelles‬",
{ ["name"] ="Bruxelles - Brussel", ["name:de"] = "Brüssel", ["name:en"] = "Brussels" , ["name:xx"] = "Brussel", ["name:af"] = "Brussel",["name:fr"]= "Bruxelles", ["name:fo"]= "Brussel" },false,false, '|','de')

checkoutput(osml10n.get_placename_from_tags,"get_placename_from_tags","‪Brixen|Bressanone‬",
{ ["name"] = "Brixen Bressanone", ["name:de"] = "Brixen", ["name:it"] = "Bressanone" },false,false, '|','de')

-- osml10n_get_placename_from_tags('"name"=>"Brixen Bressanone","name:de"=>"Brixen","name:it"=>"Bressanone"',false,false, '|')

-- printresult "‪Merano|Meran‬" <<'EOT'
-- osml10n_get_placename_from_tags('"name"=>"Merano - Meran","name:de"=>"Meran","name:it"=>"Merano"',true,false, '|') as name
-- printresult "‪Meran|Merano‬" <<'EOT'
-- osml10n_get_placename_from_tags('"name"=>"Meran - Merano","name:de"=>"Meran","name:it"=>"Merano"',true,false, '|') as name
-- printresult "‪Rom|Roma‬" <<'EOT'
-- osml10n_get_placename_from_tags('"name"=>"Roma","name:de"=>"Rom"',false,false, '|')
-- printresult "‪Prof.-Dr.-No-Str. - Dr. No St.‬" <<'EOT'
-- osml10n_get_streetname_from_tags('"name"=>"Dr. No Street","name:de"=>"Professor-Doktor-No-Straße"',false)
-- printresult "Doktor-No-Straße" <<'EOT'
-- osml10n_get_name_without_brackets_from_tags('"name"=>"Dr. No Street","name:de"=>"Doktor-No-Straße"')
-- printresult "Doktor-No-Straße" <<'EOT'
-- osml10n_get_name_without_brackets_from_tags('"name:de"=>"Doktor-No-Straße"','de',NULL,'Dr. No Street')
-- printresult "‪ул. Воздвиженка (Vozdvizhenka St.)‬" <<'EOT'
-- osml10n_get_streetname_from_tags('"name"=>"улица Воздвиженка","name:en"=>"Vozdvizhenka Street"',true,true,' ','de')
-- printresult "‪ул. Воздвиженка (ul. Vozdviženka)‬" <<'EOT'
-- osml10n_get_streetname_from_tags('"name"=>"улица Воздвиженка"',true,true,' ','de')
-- printresult "‪вул. Молока - vul. Moloka‬" <<'EOT'
-- osml10n_get_streetname_from_tags('"name"=>"вулиця Молока"',true,false,' - ','de')
-- printresult "‪вул. Молока - vul. Moloka‬" <<'EOT'
-- osml10n_get_streetname_from_tags('',true,false,' - ','de',NULL,'вулиця Молока')
-- printresult "‪주촌|Juchon‬" <<'EOT'
-- osml10n_get_placename_from_tags('"name"=>"주촌  Juchon", "name:ko"=>"주촌","name:ko_rm"=>"Juchon"',true,false,'|')
-- printresult "‪Juchon|주촌‬" <<'EOT'
-- osml10n_get_placename_from_tags('"name"=>"주촌", "name:ko"=>"주촌","name:ko_rm"=>"Juchon"',false,false,'|')
-- printresult "‪ဘုရားကိုင်လမ်း|Pha Yar Kai Rd.‬" <<'EOT'
-- osml10n_get_streetname_from_tags('"name"=>"ဘုရားကိုင်လမ်း Pha Yar Kai Road", "highway"=>"secondary", "name:en"=>"Pha Yar Kai Road", "name:my"=>"ဘုရားကိုင်လမ်း"',true,false,'|')
-- printresulty "‪ဘုရားကိုင်လမ်း|Pha Yar Kai Rd.‬" <<'EOT'
-- osml10n_get_streetname_from_tags('"name"=>"ဘုရားကိုင်လမ်း", "highway"=>"secondary", "name:en"=>"Pha Yar Kai Road", "name:my"=>"ဘုရားကိုင်လမ်း"',true,false,'|')

print(passed .. " tests passed, " .. failed .. " tests failed.")

if (failed >0) then os.exit(1) else os.exit(0) end
