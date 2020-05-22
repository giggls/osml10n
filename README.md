# A new approach for Openstreetmap l10n

Right after I got the maintainer of the [German Mapnik style](https://github.com/giggls/openstreetmap-carto-de)
in 2012 I immediately thought that it would be nice to have Latin labels on
my map rather than the respective local script.

This is when the first versions of the OSMl10n functions were born.

At this time implementing them in PL/pgSQL as PostgreSQL stored procedures
seemed to be a natural choice.

Actually this is what the [current implementation](https://github.com/giggls/mapnik-german-l10n)
still does.

However starting in 2019 this approach started to show a couple of
limitations.

Many FOSS transcription libraries are written in the python language thus we
already had to switch parts of the code to PL/Python.

This started for Thai language using tltk which worked good enough. However
trying to use this approach for Cantonese language using pinyin_jyutping_sentence
was way too slow. Importing this library takes a couple of seconds and can
not be done just once but must be done once per transaction.

Also, we noticed that PostgreSQL has a hard coded limit for pre-compiled
regular expressions, which we where using quite heavily for street-name
abbreviations. Exceeding this limit will again slow down queries in an
unacceptable way.

Discussion other approaches we now came up with the following idea.  In
future, there will be an external daemon written in python doing geolocation
aware transcription.  This daemon has already been implemented and is part
of this repository.  Currently missing (May 2020) are the l10n functions
themselves which I plan to re implement in lua which will make them usable in
osm2pgsql during import stage.

What I already have is ``cc_transcript_via_daemon.sql`` which replaces the
stored procedure for transcription by a call to this daemon.

If you have an idea for a better approach feel free to open an issue here.


## Installation of the transcription-daemon

```
apt install python3-psycopg2

pip3 install pykakasi
pip3 install tltk
pip3 install pinyin_jyutping_sentence
```

From Debian package or pip3:

## Tests

### Japan
```
curl --data "142/43/東京" http://localhost:8080
Toukyou
curl --data "jp/東京" http://localhost:8080
Toukyou
```

### China
```
curl --data "130/43/東京" http://localhost:8080
dōng jīng
curl --data "cn/東京" http://localhost:8080
dōng jīng
```

### Thailand
```
curl --data "101/16/ห้องสมุดประชาชน" http://localhost:8080
hongsamut prachachon
curl --data "th/ห้องสมุดประชาชน" http://localhost:8080
hongsamut prachachon
```

### Macau
```
curl --data "113.6/22.1/香港" http://localhost:8080
hōeng góng
curl --data "mo/香港" http://localhost:8080
hōeng góng
```

### Hongkong
```
curl --data "113.9/22.25/香港" http://localhost:8080
hōeng góng
curl --data "hk/香港" http://localhost:8080
hōeng góng
```

