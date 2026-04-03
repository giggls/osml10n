# Localization functions for Openstreetmap (osml10n)

## History

Right after I got to be the maintainer of the
[German Mapnik style](https://github.com/giggls/openstreetmap-carto-de)
in 2012 I immediately thought that it would be nice to have Latin labels on
my map rather than the respective local script.

This is when the first versions of the OSMl10n functions were born.

At this time implementing them in PL/pgSQL as PostgreSQL stored procedures
seemed to be a reasonable choice.

Actually this is what the (now deprecated)
[legacy implementation](https://github.com/giggls/mapnik-german-l10n)
does.

However already back in 2019 this approach started to show a couple of
limitations which led to the decision to relocate the transcription stuff
into data procession stage (database import or Openstreetmap file
processing), which is what this code does.

## Implementation

Localization functions are written in **Lua**, which has been chosen
because this way the code can be easilly plugged into an
[osm2pgsql](https://osm2pgsql.org) tag transformation script when importing
Openstreetmap data into **PostgreSQL** which is certainly the most common
thing to do for rendering maps.

Unfortunately however the most FOSS transcription libraries are written in
**Python** not **Lua** and we want to use them.  Thus we decided to make a
daemon doing latin transcription written in this programming language.

If you intend to use this code in other processing pipelines than
[osm2pgsql](https://osm2pgsql.org) the standalone software
[osm-tags-transform](https://github.com/osmcode/osm-tags-transform) can also
be used to add localized names to an Openstreetmap file before doing further
processing.

## Installation

Development is currently done on Debian GNU/Linux thus it is strongly
recommended to also use a Debian or Ubuntu based system for deployment.

If you are working on a Windows based system using the
[Windows-Subsystem for Linux](https://docs.microsoft.com/de-de/windows/wsl/)
is a viable option.

See [INSTALL.md](INSTALL.md) for installation instructions.

