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
apt install libunac1-dev luarocks lua5.3 liblua5.3-dev build-essential debhelper
```

### Python

```
apt install python3-venv python3-sdnotify python3-shapely libicu-dev libpython3-dev
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
sudo dpkg -i lua-unaccent_*.deb
sudo dpkg -i ../osml10n_*_all.deb
```

Afterwards python stuff needs to be installed using pip and venv. Using sudo
this will install all required stuff into /usr/local/osml10n and copy the
systemd service file into /etc/systemd/system and enable it:


```
sudo make install-daemon
```

To test if your installation is working as expected call ``make test``
afterwards.

**Make sure that the transcription-daemon is running while running tests
(``systemctl start osml10n``)**

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
osm2pgsql -G -s -O flex -d osm -S openstreetmap-carto-hstore-only-l10n.lua planet.osm.pbf
```
