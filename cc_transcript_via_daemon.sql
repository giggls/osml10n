/*
   osml10n_cc_translit
   
   an alternative country aware transliteration function using the external
   transcription daemon.

   (c) 2020 Sven Geggus <svn-osm@geggus.net>
   
   Licence AGPL http://www.gnu.org/licenses/agpl-3.0.de.html
   
   usage examples:
   select osml10n_cc_translit('東京','jp');
    ---> "toukyou"
    
   select osml10n_cc_translit('東京');
    ---> "dōng jīng"
   
*/


CREATE or REPLACE FUNCTION osml10n_cc_translit(name text, country text DEFAULT 'aq', host text DEFAULT 'localhost', port text DEFAULT '8080') RETURNS TEXT AS $$
  import plpy
  from urllib.parse import urlencode
  from urllib.request import Request, urlopen
  
  url = 'http://' + host + ':' + port
  post_data = country + '/' + name;
  try:
    request = Request(url, post_data.encode())
    tname = urlopen(request).read().decode()
  except:
    plpy.warning("unable to connect to daemon returning non transcripted name")
    return(name)

  return(tname)
$$ LANGUAGE plpython3u STABLE;
