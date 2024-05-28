
import os
import sys
import re

from setuptools import setup

PROJECT_DIR=os.path.dirname(os.path.abspath(__file__))

chfile = open('debian/changelog', 'r')

while True:
  line=chfile.readline()
  if line.startswith('osml10n'):
    p = re.compile(".*\((.*)\).*")
    result = p.search(line)
    vers=result.group(1)
    break

setup(
    name='osml10n',
    version=vers,
    install_requires=[
        "scikit-learn == 1.3.2", 
        "pykakasi == 2.2.1",
        "tltk == 1.8.0",
        "pinyin_jyutping_sentence == 1.3",
        "pyicu",
        "shapely",
        "sdnotify",
        "requests",
        "pandas",
        "scipy<1.13",  # see https://github.com/piskvorky/gensim/issues/3525 (gensim is a transitive dep of tltk)
    ],
    scripts = [ "transcription-daemon/geo-transcript-srv.py", "transcription-cli/transcribe.py" ],
    packages = [ "osml10n" ],
    package_data = { 'osml10n' : [ 'boundaries/**' ] }
)
