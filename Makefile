lua_version ?= 5.3
dest_dir ?=
prefix ?= /usr/local
target_dir=$(dest_dir)$(prefix)
py_venv ?= /tmp/osml10n

all: build install

build: check_system get_deps deb

check_system:
	test_make="foo"
	if [ -z test_make ]; then echo "Error: Please update your make to GNU Make >= 4!" && exit 2;fi

get_deps: $(py_venv)/bin/activate

$(py_venv)/bin/activate:
	python3 -m venv $(py_venv)
	. $(py_venv)/bin/activate

install: install-python install-lua

install-daemon: systemd-service install-python

install-lua:
	mkdir -p $(target_dir)/share/lua/$(lua_version)
	cp -a lua_osml10/osml10n $(target_dir)/share/lua/$(lua_version)/
	chmod -R go+rX $(target_dir)/share/lua/$(lua_version)/osml10n

systemd-service:
	sed -e "s;%PYTARGET%;$(py_venv);g" transcription-daemon/geo-transcript-srv.service.template >/etc/systemd/system/osml10n.service

test:
	cd lua_osml10/tests/ && ./runtests.lua

deb:
	(
		cd osml10n-python
		dpkg-buildpackage -b -uc
	)
	(
		cd lua_unac
		dpkg-buildpackage -b -uc
	)

install-python: check_system
	. $(py_venv)/bin/activate
	pip install .

.ONESHELL:
.SHELLFLAGS = -euc
