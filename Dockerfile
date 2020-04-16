FROM debian:buster

MAINTAINER foxcris

#repositories richtig einrichten
RUN echo 'deb http://deb.debian.org/debian buster main' > /etc/apt/sources.list
RUN echo 'deb http://deb.debian.org/debian buster-updates main' >> /etc/apt/sources.list
RUN echo 'deb http://security.debian.org buster/updates main' >> /etc/apt/sources.list

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y locales && apt-get clean
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="en_US.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF8
#automatische aktualiserung installieren + basic tools
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get install -y nano less wget curl rsyslog cron unattended-upgrades apt-transport-https htop iputils-ping gpg && apt-get clean

RUN wget -O /tmp/kubic_release.key https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/Debian_10/Release.key ; \
  if [ `gpg /tmp/kubic_release.key | grep pub | wc -l` -ne 1 ]; then echo "Mehrere Schlüssel im Kubic Keyring gefunden. Abbruch."; exit 23; fi; \
  if [ `gpg /tmp/kubic_release.key | grep 2472D6D0D2F66AF87ABA8DA34D64390375060AA4 | wc -l` -ne 1 ]; then echo "Erwarteter GPG Key von Kubic nicht gefunden. Abbruch."; exit 24; fi; \
  apt-key add /tmp/kubic_release.key; rm /tmp/kubic_release.key; \
  echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_10/ /' >> /etc/apt/sources.list; \
  apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y skopeo && apt-get clean

RUN mkdir /etc/skopeo
RUN mkdir /etc/skopeo_default
COPY mirror_default.yaml /etc/skopeo_default/mirror.yaml
VOLUME /etc/skopeo

COPY docker-entrypoint.sh /
RUN chmod 755 /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
