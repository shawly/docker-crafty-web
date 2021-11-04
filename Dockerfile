#
# Crafty Controller Dockerfile
#
# https://github.com/shawly/docker-crafty-web
#

# Set python image version
ARG PYTHON_VERSION=alpine

# Set vars for s6 overlay
ARG S6_OVERLAY_VERSION=v2.2.0.3
ARG S6_OVERLAY_BASE_URL=https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}

# Set CRAFTY vars
ARG CRAFTY_WEB_BRANCH=master
ARG CRAFTY_WEB_RELEASE=https://gitlab.com/crafty-controller/crafty-web/-/archive/${CRAFTY_WEB_BRANCH}/crafty-web-${CRAFTY_WEB_BRANCH}.tar.gz

# Set base images with s6 overlay download variable (necessary for multi-arch building via GitHub workflows)
FROM python:${PYTHON_VERSION} as python-amd64

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-amd64.tar.gz"

FROM python:${PYTHON_VERSION} as python-386

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-x86.tar.gz"

FROM python:${PYTHON_VERSION} as python-armv6

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-armhf.tar.gz"

FROM python:${PYTHON_VERSION} as python-armv7

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-arm.tar.gz"

FROM python:${PYTHON_VERSION} as python-arm64

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-aarch64.tar.gz"

FROM python:${PYTHON_VERSION} as python-ppc64le

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-ppc64le.tar.gz"

# Build crafty-web:master
FROM python-${TARGETARCH:-amd64}${TARGETVARIANT} as builder

ARG CRAFTY_WEB_RELEASE

# Change working dir
WORKDIR /crafty_web

# Install build deps and install python dependencies
RUN \
  set -ex && \
  echo "Installing build dependencies..." && \
    apk add --update --no-cache \
      build-base \
      cargo \
      git \
      libffi-dev \
      mariadb-dev \
      openssl-dev \
      python3-dev \
      rust && \
  echo "Cleaning up directories..." && \
    rm -rf /tmp/*

# Download Crafty Controller
ADD ${CRAFTY_WEB_RELEASE} /tmp/crafty-web.tar.gz

# Build wheels
RUN \
  set -ex && \
  echo "Extracting crafty-web..." && \
    tar xzf /tmp/crafty-web.tar.gz --strip-components=1 -C /crafty_web && \
  echo "Upgrading pip..." && \
    pip3 install --upgrade pip && \
  echo "Building wheels for requirements..." && \
    pip3 wheel --no-cache-dir --wheel-dir /usr/src/wheels -r requirements.txt && \
  echo "Cleaning up directories..." && \
    rm -f /usr/bin/register && \
    rm -rf .gitlab docs docker && \
    rm -f *.md .dockerignore .gitignore docker-compose.yml Dockerfile && \
    rm -rf /tmp/*

# Build crafty-web:master
FROM python-${TARGETARCH:-amd64}${TARGETVARIANT}

ENV INSTALL_JAVA16=true \
    INSTALL_JAVA11=false \
    INSTALL_JAVA8=false \
    UMASK=022 \
    FIX_OWNERSHIP=true

# Download S6 Overlay
ADD ${S6_OVERLAY_RELEASE} /tmp/s6overlay.tar.gz

# Copy wheels & crafty-web
COPY --from=builder /usr/src/wheels /usr/src/wheels
COPY --chown=1000 --from=builder /crafty_web /crafty_web

# Change working dir
WORKDIR /crafty_web

# Install runtime
RUN \
  set -ex && \
  echo "Installing runtime dependencies..." && \
    apk add --update --no-cache \
      curl \
      ca-certificates \
      coreutils \
      shadow \
      bash \
      tzdata && \
  echo "Extracting s6 overlay..." && \
    tar xzf /tmp/s6overlay.tar.gz -C / && \
  echo "Creating crafty user..." && \
    useradd -u 1000 -U -M -s /bin/false crafty && \
    mkdir -p /var/log/crafty_web && \
    chown -R nobody:nogroup /var/log/crafty_web && \
    mkdir -p /minecraft_servers /crafty_db /crafty_web/backups && \
    chown -R crafty:crafty /crafty_web /minecraft_servers /crafty_db && \
  echo "Upgrading pip..." && \
    pip3 install --upgrade pip && \
  echo "Install requirements..." && \
    pip3 install --no-index --find-links=/usr/src/wheels -r requirements.txt && \
  echo "Cleaning up directories..." && \
    rm -f /usr/bin/register && \
    # fix issue where german is set as default, changing language doesn't work anyway
    rm -f /crafty_web/app/web/translations/de_DE.csv && \
    rm -rf /tmp/*

# Add files
COPY rootfs/ /

# Define mountable directories
VOLUME ["/minecraft_servers", "/crafty_db", "/crafty_web/backups"]

# Expose ports
EXPOSE 8000 \
       25565

# Start s6
ENTRYPOINT ["/init"]
