#
# Crafty Controller Dockerfile
#
# https://github.com/shawly/docker-crafty-web
#

# Base image prefix for automated dockerhub build
ARG BASE_IMAGE_PREFIX

# Set QEMU architecture
ARG QEMU_ARCH=amd64

# Set python image tag
ARG PYTHON_VERSION=alpine

# Set vars for s6 overlay
ARG S6_OVERLAY_VERSION=v2.1.0.2
ARG S6_OVERLAY_ARCH=amd64
ARG S6_OVERLAY_RELEASE=https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz

# Set CRAFTY vars
ARG CRAFTY_WEB_REPO=https://gitlab.com/crafty-controller/crafty-web.git
ARG CRAFTY_WEB_BRANCH=master

# Provide QEMU files
FROM multiarch/qemu-user-static as qemu

# Build crafty-web:master
FROM ${BASE_IMAGE_PREFIX}python:${PYTHON_VERSION}

ARG CRAFTY_WEB_REPO
ARG CRAFTY_WEB_BRANCH
ARG QEMU_ARCH
ARG BUILD_DATE
ARG S6_OVERLAY_RELEASE

ENV S6_OVERLAY_RELEASE=${S6_OVERLAY_RELEASE} \
    CRAFTY_WEB_REPO=${CRAFTY_WEB_REPO} \
    CRAFTY_WEB_BRANCH=${CRAFTY_WEB_BRANCH} \
    INSTALL_JAVA11=true \
    INSTALL_JAVA8=false

# Add qemu-arm-static binary (copying /register is a necessary hack for amd64 systems)
COPY --from=qemu /register /usr/bin/qemu-${QEMU_ARCH}-static* /usr/bin/

# Download S6 Overlay
ADD ${S6_OVERLAY_RELEASE} /tmp/s6overlay.tar.gz

# Change working dir
WORKDIR /crafty_web

# Install deps and build binary
RUN \
  set -ex && \
  echo "Installing build dependencies..." && \
    apk add --update --no-cache --virtual build-dependencies \
      git \
      build-base \
      mariadb-dev \
      libffi-dev && \
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
  echo "Cloning crafty-web..." && \
    git clone --depth 1 ${CRAFTY_WEB_REPO} /crafty_web && \
    git checkout ${CRAFTY_WEB_BRANCH} && \
    mkdir -p /minecraft_servers /crafty_db /crafty_web/backups && \
    chown -R crafty:crafty /crafty_web /minecraft_servers /crafty_db && \
  echo "Installing python crafty_web..." && \
    pip3 install --no-cache -r requirements.txt && \
  echo "Removing unneeded build dependencies..." && \
    apk del build-dependencies && \
  echo "Cleaning up directories..." && \
    rm -f /usr/bin/register && \
    rm -rf .git .gitlab docs docker && \
    rm -f *.txt *.md .dockerignore .gitignore docker-compose.yml Dockerfile && \
    rm -rf /tmp/*

# Add files
COPY rootfs/ /

# Define mountable directories
VOLUME ["/minecraft_servers", "/crafty_db", "/crafty_web/backups"]

# Expose ports
EXPOSE 8000 \
       25565

# Metadata
LABEL \
      org.label-schema.name="crafty-web" \
      org.label-schema.description="Docker container for crafty-web" \
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/shawly/docker-crafty-web" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vendor="shawly" \
      org.label-schema.docker.cmd="docker run -d --name=crafty_web -p 8000:8000 -p 25565:25565 -v \$HOME/crafty/servers:/minecraft_servers -v \$HOME/crafty/database:/crafty_db -v \$HOME/crafty/backups:/crafty_web/backups shawly/crafty-web"

# Start s6
ENTRYPOINT ["/init"]
