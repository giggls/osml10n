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


CREATE or REPLACE FUNCTION osml10n_cc_translit(name text, country text DEFAULT 'aq', host text DEFAULT 'localhost', port int DEFAULT 8033) RETURNS TEXT AS $$
  import plpy
  import socket
  import struct

  try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((host, port))
    data = ('X/' + country + '/' + name).encode('utf-8');

    length = len(data)
    sock.sendall(struct.pack('I', length) + data)

    lendata = sock.recv(4)
    if len(lendata) == 0:
        plpy.warning("error talking to daemon returning non transcripted name")
        return(name)

    length = struct.unpack('I', lendata)
    reply = sock.recv(length[0]).decode('utf-8')

  except BaseException as err:
    plpy.warning(f"unable to connect to daemon returning non transcripted name: {err}")
    return(name)

  return(reply)
$$ LANGUAGE plpython3u STABLE;
