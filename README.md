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

Many FOSS transcription libraries are written in the **Python** language thus we
already had to switch parts of the code to **PL/Python**.

This started for Thai language using [tltk](https://pypi.org/project/tltk/)
which worked good enough. However trying to use this approach for Cantonese language using
[pinyin_jyutping_sentence](https://pypi.org/project/pinyin_jyutping_sentence/)
was way too slow. Importing this library takes a couple of seconds and can
not be done just once but must be done once per transaction.

Also, we noticed that **PostgreSQL** has a hard coded limit for pre-compiled
Regular Expressions, which we where using quite heavily for street-name
abbreviations. Exceeding this limit will again slow down queries in an
unacceptable way.

Discussing other approaches we now came up with the following idea:

* Have a transcription daemon written in Python
* Implement a library written in Lua language which can be plugged into the Lua
tag transformation script of osm2pgsql

As an Alternative ``cc_transcript_via_daemon.sql`` can be used as drop-in
replacement for the legacy code which uses the daemon for transcription
instead of stored procedures.  The main benefit of using this function is
Cantonese transcription support.

If you have an idea for an even better approach than this one feel free to
open an issue here.


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

## Installation of the Lua library

**This code will not work with lua versions below 5.3!**

On **Debian/Ubuntu** just call make deb inside ``lua_osml10`` and ``lua_unac``
directories. This will give you two Debian Packages which can be installed
on the system.

The code will also need the Lua binding for pcre which unfortunately does
not seem to be available as a Debian package.  Thus use ``luarocks install
lrexlib-pcre`` instead.

To test if your installation is working as expected call ``make
test`` inside the ``lua_osml10`` directory.

Make sure that transcription-daemon is running while running tests.
