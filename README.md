# docker-mirror installation

A docker container to mirror docker images from public registries to you own docker registry. Based on skopeo (https://github.com/containers/skopeo).
Features:
* mirroring of public docker images
  
## Configuration
 
### Configuration files, log files, business data
The following directories can be loaded from the host to keep the data and configuration files out of the container:

 | PATH in container | Description |
 | ---------------------- | ----------- |
 | /var/log | Default Logging Directory of the container. Logging information can be found in the syslog file.|
 | /etc/skopeo/mirror.yaml | Configuration file of the images to mirror |
 
### Environment variables
The following environment variables are available to configure the container on startup.

 | Environment Variable | Description |
 | ---------------------- | ----------- |
 | DOCKERMIRROR_DESTINATION_REGISTRY | Url to the destination registry to store the downloaded images. |
 | DOCKERMIRROR_DESTINATION_INSECURE_REGISTRY | Set to true if destination registry should be accessed via http |
 | DOCKERMIRROR_CRON | time configuration for the cron daemon to configure the periodic run times of apt-mirror. Example: ```APTMIRROR_CRON=* */6 * * *``` to sync every 6 hours.|
 | DOCKERMIRROR_CONFIGFILE | Path to the configuration (yaml) file of skopeo to use. Default=/etc/skopeo/mirror.yaml |
 | DOCKERMIRROR_SCOPED | Set to "true" to prefix images with the source image path, so that multiple images with the same name can be stored at destination. |
### Configuration file

The configuration file /etc/skopeo/mirror.yaml includes a list of all images and there tags which should be mirrored.
Please also take a look at the documentation from skopeo ( https://github.com/containers/skopeo/blob/master/docs/skopeo-sync.1.md ).

Example:
```
docker.io:
    images:
        debian: 
            - latest
            - buster
            - 10
        ubuntu: 
            - latest
            - bionic
            - 18.04
        foxcris/docker-apacheproxy:
            - stable
            - dev
            - latest
    tls-verify: true
```

## Container Tags

 | Tag name | Description |
 | ---------------------- | ----------- |
 | latest | Latest stable version of the container |
 | stable | Latest stable version of the container |
 | dev | latest development version of the container. Do not use in production environments! |

## Usage

### docker-compose

```
version: "3"
services:
  lstags:
    image: foxcris/docker-mirror:dev
    environment:
      - DOCKERMIRROR_DESTINATION_REGISTRY=registry:5000
      - DOCKERMIRROR_CRON=* */6 * * *
      - DOCKERMIRROR_DESTINATION_INSECURE_REGISTRY=true
      - DOCKERMIRROR_CONFIGFILE=/etc/skopeo/customconfig.yaml
      - DOCKERMIRROR_SCOPED=true
    volumes:
      - ./mirror.yaml:/etc/skopeo/customconfig.yaml:ro
    restart: always
    depends_on:
      - registry
    networks:
      - backend

  registry:
    restart: always
    image: registry:2
    ports:
      - 127.0.0.1:5000:5000
#    environment:
      #REGISTRY_HTTP_TLS_CERTIFICATE: /certs/domain.crt
      #REGISTRY_HTTP_TLS_KEY: /certs/domain.key
      #REGISTRY_AUTH: htpasswd
      #REGISTRY_AUTH_HTPASSWD_PATH: /auth/htpasswd
      #REGISTRY_AUTH_HTPASSWD_REALM: Registry Realm
    volumes:
      - /home/user/docker-registry/data/var/lib/registry:/var/lib/registry
#      - /home/user/docker-registry/data/certs:/certs
#      - /home/user/docker-registry/data/auth:/auth
    networks:
      - backend
#     network_mode: "host"



networks:
  backend:
    driver: bridge

```

### docker command line

To run the container and store the data and configuration on the local host run the following commands:
1. Create storage directroy for the configuration files, log files and data. Also create a directory to store the necessary script to create the docker container and replace it (if not using eg. watchtower)
```
mkdir /srv/docker/mirror
mkdir /srv/docker-config/mirror
```

2. Create an file to store the configuration of the environment variables
```
touch /srv/docker-config/mirror/env_file
``` 
```
DOCKERMIRROR_DESTINATION_REGISTRY=registry:5000
DOCKERMIRROR_CRON=* */6 * * *
DOCKERMIRROR_DESTINATION_INSECURE_REGISTRY=true
DOCKERMIRROR_CONFIGFILE=/etc/skopeo/customconfig.yaml
DOCKERMIRROR_SCOPED=true
```

3. Create the docker container and configure the docker networks for the container. I always create a script for that and store it under
```
touch /srv/docker-config/mirror/create.sh
```
Content of create.sh:
```
#!/bin/bash

version=stable

docker pull foxcris/docker-mirror
docker create\
 --restart always\
 --name mirror\
 --volume "./mirror_default.yaml:/etc/skopeo/customconfig.yaml:ro"
 --env-file=/srv/docker-config/mirror/env_file\
 foxcris/docker-mirror:${version}
```

4. Create replace.sh to install/update the container. Store it in
```
touch /srv/docker-config/mirror/replace.sh
```
```
#/bin/bash
docker stop mirror
docker rm mirror
./create.sh
docker start mirror
```
