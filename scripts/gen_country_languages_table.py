#!/usr/bin/env python3

# generate lua Table from http://wiki.openstreetmap.org/wiki/Nominatim/Country_Codes

import sys
from urllib.request import urlopen
import re

content=urlopen("http://wiki.openstreetmap.org/wiki/Nominatim/Country_Codes").read()

inside_table = False
col = 0
countries=[]
country={}
regex = re.compile("<.+?>", re.IGNORECASE)

for l in content.splitlines():
  line = l.decode()
  if '</table>' in line:
    inside_table = False
  if inside_table:
    if '<td' in line:
      line=regex.sub('',line).strip()
      if col == 0:
        country['iso']=line.lower()
      if col == 1:
        country['name']=line
      if col == 3:
        country['langs']='"' + line.replace(', ',',').replace(',','","') + '"'
      # check for propper table alignment (<tr><td>)
      if col == 0:
        if '<tr>' not in oldline:
          sys.stderr.write("invalid <tr><td>alignment")
          sys.exit(1)
      if col < 3:
        col+=1
      else:
        countries.append(dict(country))
        col=0
  if line == '<table class="wikitable sortable">':
    inside_table = True
  oldline=line

print("local langs = {")
for c in countries[:-1]:
  print('["%s"] = {%s},' % (c['iso'],c['langs']))

print('["%s"] = {%s}' % (countries[-1]['iso'],countries[-1]['langs']))

print('}')
print('return langs')

