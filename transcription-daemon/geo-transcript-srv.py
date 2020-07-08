#!/usr/bin/python3

from http.server import BaseHTTPRequestHandler, HTTPServer

import argparse
# as imports are very slow parse arguments first
parser = argparse.ArgumentParser(description='Server for transcription of names based on geolocation')
parser.add_argument("-b", "--bindaddr", type=str, default="localhost", help="local bind address")
parser.add_argument("-p", "--port", default=8080, help="port to listen at")
parser.add_argument("-v", "--verbose", action='store_true', help="print verbose output")       
group = parser.add_mutually_exclusive_group()
group.add_argument('-d', '--dbcon', help='PostgreSQL (psycopg2) connection string')
group.add_argument('-s', '--sqlitefile', default='country_osm_grid.db', help='SQLITE file')

args = parser.parse_args()

def vout(msg):
  if args.verbose:
    sys.stdout.write(msg)
    sys.stdout.flush()

import sys

sys.stdout.write("Loading osml10n transcription server: ")
sys.stdout.flush()
vout("\n")

from contextlib import contextmanager,redirect_stderr,redirect_stdout
from os import devnull

import os
import icu
import unicodedata
# Kanji in JP
import pykakasi
# thai language in TH
import tltk
# Cantonese transcription
with open(devnull, 'w') as fnull:
  with redirect_stderr(fnull) as err, redirect_stdout(fnull) as out:
    import pinyin_jyutping_sentence

def split_by_alphabet(str):
    strlist=[]
    target=''
    oldalphabet=unicodedata.name(str[0]).split(' ')[0]
    target=str[0]
    for c in str[1:]:
      alphabet=unicodedata.name(c).split(' ')[0]
      if (alphabet==oldalphabet):
        target=target+c
      else:
        strlist.append(target)
        target=c
      oldalphabet=alphabet
    strlist.append(target)
    return(strlist)

def thai_transcript(inpstr):
  stlist=split_by_alphabet(inpstr)

  latin = ''
  for st in stlist:
    if (unicodedata.name(st[0]).split(' ')[0] == 'THAI'):
      transcript=''
      try:
        transcript=tltk.nlp.th2roman(st).rstrip('<s/>').rstrip()
      except:
        sys.stderr.write("tltk error transcribing >%s<\n" % st)
        return(None)
      latin=latin+transcript
    else:
      latin=latin+st
  return(latin)

def cantonese_transcript(inpstr):
  stlist=split_by_alphabet(inpstr)

  latin = ''
  for st in stlist:
    if (unicodedata.name(st[0]).split(' ')[0] == 'CJK'):
      transcript=''
      try:
        transcript=pinyin_jyutping_sentence.jyutping(st, spaces=True)
      except:
        sys.stderr.write("pinyin_jyutping_sentence error transcribing >%s<\n" % st)
        return(None)
      latin=latin+transcript
    else:
      latin=latin+st
  return(latin)

class transcriptor:
  def __init__(self):

    # ICU transliteration instance
    self.icutr = icu.Transliterator.createInstance('Any-Latin').transliterate

    # Kanji to Latin transcription instance via pykakasi
    kakasi = pykakasi.kakasi()
    kakasi.setMode("H","a")
    kakasi.setMode("K","a")
    kakasi.setMode("J","a")
    kakasi.setMode("r","Hepburn")
    kakasi.setMode("s", True)
    kakasi.setMode("E", "a")
    kakasi.setMode("a", None)
    kakasi.setMode("C", True)
    self.kakasi_converter  = kakasi.getConverter()
  
  def transcript(self, country, unistr):
    if (country == ""):
      vout("doing non-country specific transcription for >>%s<<\n" % unistr)
    else:
      vout("doing transcription for >>%s<< (country %s)\n" % (unistr,country))
    if country == 'jp':
      kanji = self.kakasi_converter.do(unistr)
      return(' '.join(kanji.split()))
    
    if country == 'th':
      return(thai_transcript(unistr))
      
    if country in ['mo','hk']:
      return(cantonese_transcript(unistr))
  
    return(unicodedata.normalize('NFC', self.icutr(unistr)))

# convert lon/lat to countrycode via PostgreSQL
class Coord2Country_psql:
  def __init__(self):
      import psycopg2
      self.sql = """
      SELECT country_code from country_osm_grid
      WHERE st_contains(geometry, ST_GeomFromText('POINT(%s %s)', 4326))
      ORDER BY area LIMIT 1;
      """
      try:
        self.conn = psycopg2.connect(args.dbcon)
      except:
        sys.stderr.write("Unable to connect to database using %s " % args.dbcon)
        sys.stderr.write("falling back to countrycode-only mode\n")
        self.ready = False
        return
      self.cur = self.conn.cursor()
      self.ready = True
  def getCountry(self,lon,lat):
    try:
      self.cur.execute(self.sql % (lon,lat))
      rows = self.cur.fetchall()
      if len(rows) == 0:
        return('')
      else:
        return(rows[0][0])
    except Exception as e:
      sys.stderr.write("Database query error:\n")
      sys.stderr.write(str(e))
      sys.exit(1)

# convert lon/lat to countrycode via SQLITE
class Coord2Country_sqlite:
  def __init__(self):
    # check if sqlite file is available
    fn = os.path.realpath(args.sqlitefile)
    if not os.path.isfile(fn):
      sys.stderr.write("Unable to open SQLITE file %s, " % args.sqlitefile)
      sys.stderr.write("falling back to countrycode-only mode\n")
      self.ready = False
      return
    import sqlite3
    self.sql = """
    SELECT country_code
    FROM country_osm_grid
    WHERE st_contains(geometry, ST_GeomFromText('POINT(%s %s)', 4326))
    AND ROWID IN (
      SELECT ROWID
      FROM SpatialIndex
      WHERE f_table_name = 'country_osm_grid'
      AND search_frame = ST_GeomFromText('POINT(%s %s)', 4326)
    ) ORDER BY area LIMIT 1;
    """
    self.conn = sqlite3.connect(fn)
    self.conn.enable_load_extension(True)
    self.conn.load_extension("mod_spatialite")
    self.cur = self.conn.cursor()
    self.ready = True

  def getCountry(self,lon,lat):
    self.cur.execute(self.sql % (lon,lat,lon,lat))
    rows = self.cur.fetchall()
    if len(rows) == 0:
      return('')
    else:
      return(rows[0][0])

# convert lon/lat to countrycode via PostgreSQL
class Coord2Country:
  def __init__(self):
    if args.dbcon is not None:
      vout("Using PostgreSQL for country_osm_grid!\n")
      self.co2c = Coord2Country_psql()
    else:
      vout("Using SQLITE for country_osm_grid!\n")
      self.co2c = Coord2Country_sqlite()
    self.ready = self.co2c.ready
  def getCountry(self,lon,lat):
    # if no coordinates are given
    if (lat == "") and (lon == ""):
      return('')
    country = self.co2c.getCountry(lon,lat)
    if (country == ""):
      vout("country for %s/%s is unknown\n" % (lon,lat))
    else:
      vout("country for %s/%s is %s\n" % (lon,lat,country))
    return(country)

class httpServer(BaseHTTPRequestHandler):

  co2c=Coord2Country()
  tc=transcriptor()

  def do_GET(self):
    self.send_response(200)
    self.send_header("Content-type", "text/plain")
    self.end_headers()
    self.wfile.write(b"This server is POST only!\n")

  def do_POST(self):
    content_length = int(self.headers['Content-Length'])
    post_data = self.rfile.read(content_length).decode('utf-8')
    # We support the following post data
    # cc/string
    # lon/lat/string
    qs = post_data.split('/',2)
    if (len(qs) == 2):
      (cc,name) = qs
    else:
      (lon,lat,name) = qs
      if httpServer.co2c.ready:
        cc=httpServer.co2c.getCountry(lon,lat)
      else:
        cc = ""

    self.send_response(200)
    self.send_header("Content-type", "text/plain; charset=UTF-8")
    self.end_headers()
    self.wfile.write(bytes(httpServer.tc.transcript(cc,name),"utf-8"))

  def log_message(self, format, *args):
    return



if __name__ == "__main__":
  webServer = HTTPServer((args.bindaddr, args.port), httpServer)

  sys.stdout.write("ready.\n")
  try:
    webServer.serve_forever()
  except KeyboardInterrupt:
    pass

  webServer.server_close()
