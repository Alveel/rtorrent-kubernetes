# syntax=docker/dockerfile:1
# This Dockerfile builds a minimal statically compiled rtorrent
ARG BUILD_UBI_VERSION="9.5"
ARG RUNTIME_UBI_VERSION="9.5"

FROM registry.access.redhat.com/ubi9/ubi:$BUILD_UBI_VERSION AS builder

ARG TINYXML_VERSION="11.0.0"
ARG RTORRENT_VERSION="0.15.1"

# Install dependencies
RUN dnf -y update-minimal --security --sec-severity=Important --sec-severity=Critical \
    && dnf install -y \
    gcc-c++ \
    cmake \
    libtool \
    pkgconf-pkg-config \
    diffutils \
    bzip2 \
    zlib-devel \
    ncurses-devel \
    openssl-devel \
    libcurl-devel \
    && dnf clean all

# Add a non-root user and switch to it
RUN useradd -m builder
USER builder

# Set the working directory
WORKDIR /home/builder

# Set up the build environment
RUN mkdir -p /home/builder/static

# Download and compile tinyxml2
RUN curl -sL "https://github.com/leethomason/tinyxml2/archive/refs/tags/${TINYXML_VERSION}.tar.gz" | tar xz \
    && cd tinyxml2-${TINYXML_VERSION} \
    && mkdir build && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX=/home/builder/static -DBUILD_SHARED_LIBS=OFF .. \
    && make -j $(nproc) \
    && make -j $(nproc) test \
    && make install

# Download and compile libtorrent
RUN curl -sL "https://github.com/rakshasa/rtorrent/releases/download/v${RTORRENT_VERSION}/libtorrent-${RTORRENT_VERSION}.tar.gz" | tar xz \
    && cd libtorrent-${RTORRENT_VERSION} \
    && autoreconf -fiv \
    && export CXXFLAGS+=' -fno-strict-aliasing' \
    && ./configure \
      --prefix=/home/builder/static \
      --disable-debug \
      --enable-static \
      --disable-shared \
    && make -j $(nproc) \
    && make install

# Download and compile rtorrent
RUN curl -sL https://github.com/rakshasa/rtorrent/releases/download/v${RTORRENT_VERSION}/rtorrent-${RTORRENT_VERSION}.tar.gz | tar xz \
    && cd rtorrent-${RTORRENT_VERSION} \
    && autoreconf -fiv \
    && ./configure \
        --prefix=/home/builder/static \
        --disable-debug \
        --enable-static \
        --disable-shared \
        --with-xmlrpc-tinyxml2 \
        PKG_CONFIG_PATH='/home/builder/static/lib/pkgconfig' \
    && make -j $(nproc) \
    && make install

FROM registry.access.redhat.com/ubi9/ubi-minimal:$RUNTIME_UBI_VERSION

ARG RTORRENT_VERSION="0.15.1"

# Configure runtime user
RUN useradd -r -u 1001 -g 0 torrent \
    && mkdir -p /opt/app-root/{config,download,log,session,watch} \
    && chown -R torrent:0 /opt/app-root \
    && chmod -R g=u /opt/app-root
ENV HOME=/opt/app-root

USER torrent

WORKDIR /opt/app-root

# Copy the built binary from the builder stage as well as auxiliary files
COPY --from=builder /home/builder/static/bin/rtorrent /usr/local/bin/rtorrent
COPY --chmod=550 entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chmod=664 rtorrent.rc.dist /usr/local/share/doc/rtorrent/

# Expose the configuration and data directories
VOLUME ["/opt/app-root/config", "/opt/app-root/download", "/opt/app-root/log", "/opt/app-root/session", "/opt/app-root/watch"]

# Expose the ports used by rtorrent
# Listening port
EXPOSE 50000
# DHT port
EXPOSE 62882

LABEL name="Alveel/rtorrent" \
      vendor="Alwyn Kik <alwyn at kik dot pw>" \
      version=$RTORRENT_VERSION \
      release="1" \
      summary="rtorrent container image" \
      description="rtorrent is statically compiled into a single binary." \
      url="https://github.com/Alveel/rtorrent-kubernetes"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["rtorrent"]
