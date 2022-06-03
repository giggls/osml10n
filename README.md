# Localization functions for Openstreetmap (osml10n)

As most FOSS transcription libraries are written in **Python** we decided to
make a daemon doing latin transcription written in this programming
language.

However the actual localization functions are written in **Lua**.

**Lua** hase been chosen because this way the code can be easilly plugged
into an [osm2pgsql](https://osm2pgsql.org) flex-mode tag transformation
script when importing Openstreetmap data into **PostgreSQL** which is likely
the most common thing to do for rendering maps.

If you intend to use this code in other import pipelines the standalone
software [osm-tags-transform](https://github.com/osmcode/osm-tags-transform)
can also be used to add localized names to an Openstreetmap file before
doing further processing.

## Installation

Development is currently done on Debian GNU/Linux thus it is strongly
recommended to also use a Debian or Ubuntu based system for deployment.

If you are working on a Windows based system using the
[Windows-Subsystem for Linux]https://docs.microsoft.com/de-de/windows/wsl/
is a viable option.

See [INSTALL.md] for installation instructions.

## History

Right after I got to be the maintainer of the
[German Mapnik style](https://github.com/giggls/openstreetmap-carto-de)
in 2012 I immediately thought that it would be nice to have Latin labels on
my map rather than the respective local script.

This is when the first versions of the OSMl10n functions were born.

At this time implementing them in PL/pgSQL as PostgreSQL stored procedures
seemed to be a natural choice.

Actually this is what the (now deprecated)
[legacy implementation](https://github.com/giggls/mapnik-german-l10n)
does.

Starting in 2019 this approach started to show a couple of limitations.

Most FOSS transcription libraries are written in the **Python** language thus we
already had to switch parts of the code to **PL/Python**.

This started for Thai language using [tltk](https://pypi.org/project/tltk/)
which worked good enough. However trying to use this approach for Cantonese language using
[pinyin_jyutping_sentence](https://pypi.org/project/pinyin_jyutping_sentence/)
was way too slow. Importing this library takes a couple of seconds and can
not be done just once but must be done once per SQL transaction.

Also, we noticed that **PostgreSQL** has a hard coded limit for pre-compiled
regular expressions, which we were using quite heavily for doing street-name
abbreviations. Exceeding this limit will again slow down queries in an
unacceptable way.

For this reason we decided to relocate the transcription stuff into data
procession stage (database import or Openstreetmap file processiong).
