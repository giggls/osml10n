# Installing Openstreetmap l10n

Currently Openstreetmap l10n uses the **Python** as well as **Lua**
programming language which unfortunatelly somewhat complicates the
installation procedure.

On Debian/Ubuntu (Currently tested on Debian 11) the most easy path for
installation is as follows:

## Prerequisites

### Lua

**This code will not work with lua versions below 5.3!**

```
apt install libunac1-dev luarocks lua5.3 libpcre3-dev liblua5.3-dev

luarocks install lrexlib-pcre
```

We hope to get rid of lrexlib-pcre in future versions of this code replacing
them with native Lua patterns.

### Python

```
apt install python3-icu python3-shapely python3-pip python3-sdnotify python3-requests

pip install pykakasi
pip install tltk
pip install pinyin_jyutping_sentence
```

Might need to use ``pip3`` instead of ``pip`` in older versions of Debin/Ubuntu.

## Installation

On **Debian/Ubuntu** just call ``make deb`` after installing Python and Lua
prerequisites inside base and ``lua_unac`` directories.

This will give you two Debian packages which can be installed on the system.

To test if your installation is working as expected call ``make test``
afterwards.

Make sure that the transcription-daemon is running while running tests (will
auto-start after the Debian packages have been installed).

If you get errors while calling ``make test`` please report them on Github.

I am particularly interested in problems regarding the current LTS versions
of Ubuntu and other Linux distributions than Debian stable as I am not using
them myself.

## Rendering a l10n version of Openstreetmap Carto

If you inted to use this code for rendering a localized version of Openstreetmap Carto
a suitable version of calling osm2pgsql would be as follows:

```
osm2pgsql -G -O flex -d osm -S openstreetmap-carto-hstore-only-l10n.lua planet.osm.pbf
```

At the time of writing this requires the current master branch of osm2pgsql
which will include the most recent changes to the flex backend.

Version 1.6.0 or older are not recent enough!
