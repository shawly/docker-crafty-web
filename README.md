# Docker container for Crafty Controller
[![Docker Automated build](https://img.shields.io/badge/docker%20build-automated-brightgreen)](https://github.com/shawly/docker-crafty-web/actions) [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/shawly/docker-crafty-web/Docker)](https://github.com/shawly/docker-crafty-web/actions) [![Docker Pulls](https://img.shields.io/docker/pulls/shawly/crafty-web)](https://hub.docker.com/r/shawly/crafty-web) [![Docker Image Size (tag)](https://img.shields.io/docker/image-size/shawly/crafty-web/latest)](https://hub.docker.com/r/shawly/crafty-web) [![GitHub Release](https://img.shields.io/github/release/shawly/docker-crafty-web.svg)](https://github.com/shawly/docker-crafty-web/releases/latest)

This is a Docker container for Crafty Controller. A webinterface for setting up and controlling minecraft servers (e.g. Vanilla, Spigot, PaperMC, Sponge etc.).

---

[![crafty-web](https://dummyimage.com/400x110/ffffff/575757&text=Crafty%20Controller)](https://gitlab.com/crafty-controller/crafty-web)

Crafty Controller by [Phillip Tarrant](https://gitlab.com/crafty-controller/crafty-web).

---
## Table of Content

   * [Docker container for crafty-web](#docker-container-for-crafty-web)
      * [Table of Content](#table-of-content)
      * [Supported Architectures](#supported-architectures)
      * [Quick Start](#quick-start)
      * [Usage](#usage)
         * [Environment Variables](#environment-variables)
         * [Data Volumes](#data-volumes)
         * [Ports](#ports)
         * [Changing Parameters of a Running Container](#changing-parameters-of-a-running-container)
      * [Docker Compose File](#docker-compose-file)
      * [Docker Image Update](#docker-image-update)
      * [User/Group IDs](#usergroup-ids)
      * [Support or Contact](#support-or-contact)

## Supported Architectures

The architectures supported by this image are:

| Architecture | Status |
| :----: | ------ |
| x86-64 | working |
| x86 | untested |
| arm64 | untested |
| armv7 | untested |
| armhf | untested |
| ppc64le | untested |

*I'm declaring the arm images as **untested** because I only own an older first generation RaspberryPi Model B+ I can't properly test the image on other devices, technically it should work on all RaspberryPi models and similar SoCs. While emulating the architecture with qemu works and can be used for testing, I can't guarantee that there will be no issues, just try it.*

## Quick Start

**NOTE**: The Docker command provided in this quick start is given as an example
and parameters should be adjusted to your need.

Launch the crafty-web docker container with the following command:
```
docker run -d \
    --name=crafty-web \
    -p 8000:8000 \
    -p 25565:25565 \
    -v $HOME/crafty/servers:/minecraft_servers:rw \
    -v $HOME/crafty/database:/crafty_db:rw \
    -v $HOME/crafty/backups:/crafty_web/backups:rw \
    shawly/crafty-web
```

Where:
  - `$HOME/crafty/servers`: This location contains files from your minecraft servers.
  - `$HOME/crafty/database`: This location contains the database files for crafty.
  - `$HOME/crafty/backups`: This location contains the backups made via the web interface.


## Usage

```
docker run [-d] \
    --name=crafty-web \
    [-e <VARIABLE_NAME>=<VALUE>]... \
    [-v <HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]]... \
    [-p <HOST_PORT>:<CONTAINER_PORT>]... \
    shawly/crafty-web
```
| Parameter | Description |
|-----------|-------------|
| -d        | Run the container in background.  If not set, the container runs in foreground. |
| -e        | Pass an environment variable to the container.  See the [Environment Variables](#environment-variables) section for more details. |
| -v        | Set a volume mapping (allows to share a folder/file between the host and the container).  See the [Data Volumes](#data-volumes) section for more details. |
| -p        | Set a network port mapping (exposes an internal container port to the host).  See the [Ports](#ports) section for more details. |

### Environment Variables

To customize some properties of the container, the following environment
variables can be passed via the `-e` parameter (one for each variable).  Value
of this parameter has the format `<VARIABLE_NAME>=<VALUE>`.

| Variable       | Description                                  | Default |
|----------------|----------------------------------------------|---------|
|`USER_ID`| ID of the user the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`GROUP_ID`| ID of the group the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`TZ`| [TimeZone] of the container.  Timezone can also be set by mapping `/etc/localtime` between the host and the container. | `Etc/UTC` |
|`INSTALL_JAVA16`| This executes a script which installs the Java 16 runtime if it isn't already installed. This version is needed for Minecraft version 1.17+ | `true` |
|`INSTALL_JAVA11`| This executes a script which installs the Java 11 runtime if it isn't already installed. For the Minecraft server to work, java 8 and/or 11 needs to be installed! | `false` |
|`INSTALL_JAVA8`| This executes a script which installs the Java 8 runtime if it isn't already installed. Use this if you need Java 8, for legacy servers for example. | `false` |
|`UMASK`| This sets the umask for the crafty control process in the container. | `022` |
|`FIX_OWNERSHIP`| This executes a script which checks if the USER_ID & GROUP_ID changed from the default of 1000 and fixes the ownership of the /crafty_web folder if necessary, otherwise crafty_web wont't start. It's recommended to leave this enabled if you changed the USER_ID or GROUP_ID. | `true` |

### Data Volumes

The following table describes data volumes used by the container.  The mappings
are set via the `-v` parameter.  Each mapping is specified with the following
format: `<HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]`.

| Container path  | Permissions | Description |
|-----------------|-------------|-------------|
|`/minecraft_servers`| rw | This is the path crafty-web will use for minecraft servers. |
|`/crafty_db`| rw | This is the path crafty-web will to store database files. |
|`/crafty_web/backups`| rw | This is the path crafty-web use for making backups of minecraft servers. |

### Ports

Here is the list of ports used by the container.  They can be mapped to the host
via the `-p` parameter (one per port mapping).  Each mapping is defined in the
following format: `<HOST_PORT>:<CONTAINER_PORT>`.  The port number inside the
container cannot be changed, but you are free to use any port on the host side.

| Port | Mapping to host | Description |
|------|-----------------|-------------|
| 25565 | Mandatory | Port used for minecraft servers. |
| 8000 | Mandatory | Port used for serving the webinterface itself. |
| 25000-26000 | Optional | Ports usable for more minecraft servers. |

### Changing Parameters of a Running Container

As seen, environment variables, volume mappings and port mappings are specified
while creating the container.

The following steps describe the method used to add, remove or update
parameter(s) of an existing container.  The generic idea is to destroy and
re-create the container:

  1. Stop the container (if it is running):
```
docker stop crafty-web
```
  2. Remove the container:
```
docker rm crafty-web
```
  3. Create/start the container using the `docker run` command, by adjusting
     parameters as needed.

## Docker Compose File

Here is an example of a `docker-compose.yml` file that can be used with
[Docker Compose](https://docs.docker.com/compose/overview/).

Make sure to adjust according to your needs.  Note that only mandatory network
ports are part of the example.

```yaml
version: '3'
services:
  crafty-web:
    image: shawly/crafty-web
    environment:
      - TZ: Europe/Berlin
      - USER_ID: 500
      - GROUP_ID: 500
      - INSTALL_JAVA8: false
      - INSTALL_JAVA11: false
      - INSTALL_JAVA16: true
    ports:
      - "25565:25565"
      - "8000:8000"
    volumes:
      - "$HOME/crafty/servers:/minecraft_servers:rw"
      - "$HOME/crafty/database:/crafty_db:rw"
      - "$HOME/crafty/backups:/crafty_web/backups:rw"
```

## Docker Image Update

If the system on which the container runs doesn't provide a way to easily update
the Docker image, the following steps can be followed:

  1. Fetch the latest image:
```
docker pull shawly/crafty-web
```
  2. Stop the container:
```
docker stop crafty-web
```
  3. Remove the container:
```
docker rm crafty-web
```
  4. Start the container using the `docker run` command.

## User/Group IDs

When using data volumes (`-v` flags), permissions issues can occur between the
host and the container.  For example, the user within the container may not
exists on the host.  This could prevent the host from properly accessing files
and folders on the shared volume.

To avoid any problem, you can specify the user the application should run as.

This is done by passing the user ID and group ID to the container via the
`USER_ID` and `GROUP_ID` environment variables.

To find the right IDs to use, issue the following command on the host, with the
user owning the data volume on the host:

    id <username>

Which gives an output like this one:
```
uid=1000(myuser) gid=1000(myuser) groups=1000(myuser),4(adm),24(cdrom),27(sudo),46(plugdev),113(lpadmin)
```

The value of `uid` (user ID) and `gid` (group ID) are the ones that you should
be given the container.
