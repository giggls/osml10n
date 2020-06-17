# lua version to build against
LUAV?=5.3

TARGETDIR=$(DESTDIR)/usr/lib/x86_64-linux-gnu/lua/$(LUAV)/

unaccent.so: lua_unac.c
	gcc -Wall -shared -fPIC -o $@ -I/usr/include/lua$(LUAV) -llua$(LUAV) -lunac $<

install: unaccent.so
	install -m 644 unaccent.so $(TARGETDIR)

deb:
	dpkg-buildpackage -b -uc

clean:
	rm -f unaccent.so