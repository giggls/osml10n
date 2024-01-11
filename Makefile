
LUAV=5.3

prefix = /usr/local

TARGETDIR=$(DESTDIR)$(prefix)

PYTARGET=$(prefix)/osml10n

build:
	echo "These are lua and python scripts, there is nothing to build here"

install: install-lua

install-daemon: systemd-service
	python3 -m venv $(PYTARGET)
	$(PYTARGET)/bin/pip install .

install-lua:
	mkdir -p $(TARGETDIR)/share/lua/$(LUAV)
	cp -a lua_osml10/osml10n $(TARGETDIR)/share/lua/$(LUAV)/
	chmod -R go+rX $(TARGETDIR)/share/lua/$(LUAV)/osml10n

systemd-service:
	sed -e "s;%PYTARGET%;$(PYTARGET);g" transcription-daemon/geo-transcript-srv.service.template >/etc/systemd/system/osml10n.service

test:
	cd lua_osml10/tests/ && ./runtests.lua

deb:
	dpkg-buildpackage -b -uc

clean:
	echo "there is nothing to clean"
