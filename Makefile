
LUAV=5.3

prefix = /usr/local

TARGETDIR=$(DESTDIR)$(prefix)

build:
	echo "These are lua and python scripts, there is nothing to build here"

install: install-lua install-daemon

install-daemon: systemd-service
	mkdir -p $(TARGETDIR)/bin
	cp -a transcription-daemon/geo-transcript-srv.py $(TARGETDIR)/bin
	chmod 755 $(TARGETDIR)/bin/geo-transcript-srv.py
	mkdir -p $(TARGETDIR)/share/osml10n/boundaries
	cp -a boundaries/* $(TARGETDIR)/share/osml10n/boundaries
	cp transcription-cli/transcribe.py $(TARGETDIR)/bin
	chmod 755 $(TARGETDIR)/bin/transcribe.py

install-lua:
	mkdir -p $(TARGETDIR)/share/lua/$(LUAV)
	cp -a lua_osml10/osml10n $(TARGETDIR)/share/lua/$(LUAV)/
	chmod -R go+rX $(TARGETDIR)/share/lua/$(LUAV)/osml10n

systemd-service:
	sed -e 's;/usr/local;/usr;g' transcription-daemon/geo-transcript-srv.service >debian/osml10n.service

test:
	cd lua_osml10/tests/ && ./runtests.lua

deb: systemd-service
	dpkg-buildpackage -b -uc

clean:
	echo "there is nothing to clean"
