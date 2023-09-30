# Installing Openstreetmap l10n

Currently Openstreetmap l10n uses the **Python** as well as **Lua**
programming language which unfortunatelly somewhat complicates the
installation procedure.

On Debian/Ubuntu (Currently tested on Debian 12) the most easy path for
installation is as follows:

## Prerequisites

### Lua

**This code will not work with lua versions below 5.3!**

```
apt install libunac1-dev luarocks lua5.3 liblua5.3-dev
```

We hope to get rid of lrexlib-pcre in future versions of this code replacing
them with native Lua patterns.

### Python

```
apt install python3-icu python3-shapely python3-pip python3-sdnotify python3-requests python3-sklearn

pip install pykakasi -U --break-system-packages
pip install tltk -U --break-system-packages
pip install pinyin_jyutping_sentence -U --break-system-packages
```

I will need to find out how to get rid of this somewhat missleading
"break-system-packages" option. It won't break anything because these
packages are not available as Debian packages.

Unfortunately these libraries (especially tltk) seem to be a somewhat
moving target.  Here are the versions this code has been tested with:

* pykakasi 2.2.1
* tltk 1.6.8
* pinyin_jyutping_sentence 1.3

Thus if this stuff does not work try the following instead of the above pip
calls:

```
pip install pykakasi==2.2.1
pip install tltk==1.6.8
pip install pinyin_jyutping_sentence==1.3
```

## Installation

On **Debian/Ubuntu** just call ``make deb`` after installing Python and Lua
prerequisites inside base and ``lua_unac`` directories.

To do this the ``dpkg-dev`` package has to be installed.
``dpkg-buildpackage`` might complain about further dependencies in this
process. Just install them as requested in this case.

This will give you two Debian packages which should to be installed on the
system:

```
dpkg -i lua-unaccent_*.deb
dpkg -i ../osml10n_*_all.deb
```

To test if your installation is working as expected call ``make test``
afterwards.

**Make sure that the transcription-daemon is running while running tests**
(will auto-start after the Debian packages have been installed).

If you get errors while calling ``make test`` please report them on Github.

I am particularly interested in problems regarding the current LTS versions
of Ubuntu and other Linux distributions than Debian stable as I am not using
them myself.

## Rendering a l10n version of Openstreetmap Carto

If you inted to use this code for rendering a localized version of Openstreetmap Carto
calling osm2pgsql as follows should work.

Have a look at https://osm2pgsql.org/doc/ for further information.

**This will require osm2pgsql version 1.7.0 or newer!**

```
osm2pgsql -G -O flex -d osm -S openstreetmap-carto-hstore-only-l10n.lua planet.osm.pbf
```
