ARG debian_version=12

FROM debian:${debian_version}-slim as builder

WORKDIR /app
# hadolint ignore=DL3008
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get --yes update \
    && apt-get install --no-install-recommends --yes eatmydata
RUN export DEBIAN_FRONTEND=noninteractive \
    && eatmydata apt-get --yes upgrade \
    && eatmydata apt-get install --yes --no-install-recommends \
    build-essential \
    debhelper \
    dh-python \
    libicu-dev \
    libpython3-dev \
    libunac1-dev \
    luarocks \
    lua5.3 \
    liblua5.3-dev \
    pkg-config \
    python3-all \
    python3-venv \
    python3-setuptools \
    python3-wheel \
    make

COPY --link ./ ./
RUN make build

FROM debian:${debian_version}-slim as worker
ARG osml10n_version=1.2.0
ARG lua_unaccent_version="1.8-1"
ARG arch=amd64

WORKDIR /app

COPY --link --from=builder /app/osml10n_${osml10n_version}_all.deb ./
COPY --link --from=builder /app/lua-unaccent_${lua_unaccent_version}_${arch}.deb ./
COPY --link entrypoint.sh ./

# hadolint ignore=DL3008,DL3013,SC1091
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get --yes update \
    && apt-get install --yes --no-install-recommends \
        python3-venv \
    && apt-get install --yes --no-install-recommends "./lua-unaccent_${lua_unaccent_version}_${arch}.deb" \
    && apt-get install --yes --no-install-recommends "./osml10n_${osml10n_version}_all.deb" \
    && rm -rf ./*deb \
    && python3 -m venv --system-site-packages venv \
    && . venv/bin/activate \
    && pip install --no-cache-dir wheel \
    && pip install --no-cache-dir --requirement /usr/lib/python3/dist-packages/osml10n-${osml10n_version}.egg-info/requires.txt \
    && apt-get --yes clean \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/app/entrypoint.sh"]
