# Base Image
FROM debian:bookworm-slim AS base
RUN apt-get update && apt-get dist-upgrade -y && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata && \
  rm -rf /var/lib/apt/lists/*

# Build Dependencies
FROM base AS build-deps
ARG OPENSSL_VERSION="3.4.1"
ARG PY_VERSION="3.13.2"
ARG QUICK_BUILD="true"

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  build-essential \
  libbz2-dev \
  libffi-dev \
  libgdbm-dev \
  liblzma-dev \
  libncurses5-dev \
  libnss3-dev \
  libsqlite3-dev \
  wget \
  zlib1g-dev \
  ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN export BASE_PYTHON_VERSION=$(echo ${PY_VERSION} | sed -r "s/([0-9]+\.[0-9]+\.[0-9]+).*/\1/") && \
  wget -qc https://www.python.org/ftp/python/${BASE_PYTHON_VERSION}/Python-${PY_VERSION}.tgz && \
  tar xzf Python-${PY_VERSION}.tgz && \
  wget -qc https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
  tar xzf openssl-${OPENSSL_VERSION}.tar.gz

# Build OpenSSL
WORKDIR /src/openssl-${OPENSSL_VERSION}
RUN ./config -Wl,-rpath=/usr/local/ssl/lib64:/usr/local/lib \
  -Wl,--enable-new-dtags \
  --prefix=/usr/local/ssl --openssldir=/usr/local/ssl
RUN make -s -j$(nproc) && make -s install

# Build Python
WORKDIR /src/Python-${PY_VERSION}
ENV LDFLAGS="-L/usr/local/ssl/lib64/ -Wl,-rpath=/usr/local/ssl/lib64:/usr/local/lib"
ENV LD_LIBRARY_PATH="/usr/local/ssl/lib/:/usr/local/ssl/lib64/"
ENV CPPFLAGS="-I/usr/local/ssl/include -I/usr/local/ssl/include/openssl"

RUN if [ "${QUICK_BUILD}" = "true" ]; then OPTIMIZATION=""; else OPTIMIZATION="--enable-optimizations --with-lto"; fi && ./configure --with-openssl=/usr/local/ssl \
  --enable-loadable-sqlite-extensions \
  --enable-shared \
  --with-openssl-rpath=auto ${OPTIMIZATION}
RUN make -s -j$(nproc)
RUN make -s -j$(nproc) altinstall

# **Strip binaries to reduce size**
RUN strip --strip-unneeded /usr/local/bin/python${PY_VERSION%.*} || true

# **Remove unnecessary files**
RUN find /usr/local -depth \( \
  \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) -o \
  \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
  \) -exec rm -rf {} + \
  && rm -rf /usr/local/ssl/include /usr/local/ssl/share \
  /usr/local/lib/python${PY_VERSION%.*}/config-*/test \
  /usr/local/lib/python${PYTHON_VERSION%.*}/config-${PYTHON_VERSION%.*}-x86_64-linux-gnu/libpython${PYTHON_VERSION%.*}.a \
  /usr/local/ssl/lib64/libcrypto.a \
  /usr/local/ssl/lib64/libssl.a 
# **Compress binaries with UPX (optional, saves ~10MB)**
# Download UPX manually (replace version if needed)
RUN wget -qO /tmp/upx.tar.xz https://github.com/upx/upx/releases/download/v5.0.0/upx-5.0.0-amd64_linux.tar.xz && \
  tar -xJf /tmp/upx.tar.xz --strip-components=1 -C /usr/local/bin/ upx-5.0.0-amd64_linux/upx && \
  chmod +x /usr/local/bin/upx && \
  upx --best --lzma /usr/local/bin/python${PY_VERSION%.*} || true && \
  rm -f /usr/local/bin/upx /tmp/upx.tar.xz

# Final Runtime Image
FROM base AS final
ARG PY_VERSION="3.13.2"
ARG CREATION_COMMIT_SHA
RUN  apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  bzip2 ca-certificates curl libffi8 libgdbm6 liblzma5 libncurses6 libnss3 sqlite3 wget zlib1g \
  && update-ca-certificates && apt-get clean && \
  rm -rf /var/lib/apt/lists/* /usr/share/locale/* /usr/share/man/* /usr/share/doc/*
COPY --from=build-deps /usr/local/ /usr/local/
# OpenSSL looks into $OPENSSLDIR/certs as CA trust store. By default this is
# empty, and installing ca-certificates with apt-get populates it in the system
# openssl folder at /usr/lib/ssl/certs/. Our compiled openssl looks into
# /usr/local/ssl/certs, we create a symlink between the two to let Python access
# the OS trust store.
RUN mkdir -p /usr/local/ssl && ln -sf /usr/lib/ssl/certs /usr/local/ssl/certs
# We also set the env variables to have aiohttp and requests look
# to the correct location for CA certificates.
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
ENV LD_LIBRARY_PATH="/usr/local/ssl/lib/:/usr/local/ssl/lib64/"
ENV CREATION_COMMIT_SHA=${CREATION_COMMIT_SHA}

WORKDIR /usr/local/bin
RUN ln -sf python${PY_VERSION%.*} python && \
  ln -sf python${PY_VERSION%.*} python3

CMD ["/usr/local/bin/python3"]