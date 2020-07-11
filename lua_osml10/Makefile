# lua version to build against
LUAV?=5.3

TARGETDIR=$(DESTDIR)/usr/share/lua/$(LUAV)/

dummy:
	echo "there is nothing to make here"

install:
	mkdir -p $(TARGETDIR)
	cp -a osml10n $(TARGETDIR)
	chmod -R go+rX $(TARGETDIR)/osml10n

deb:
	dpkg-buildpackage -b -uc

clean:
	echo "there is nothing to clean"