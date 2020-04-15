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
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get install -y nano less wget curl rsyslog cron unattended-upgrades apt-transport-https htop iputils-ping&& apt-get clean

#download and install lstags https://github.com/ivanilves/lstags
ARG VERSION=1.2.15
ARG URL=https://github.com/ivanilves/lstags/releases/download/v1.2.15/lstags-linux-v1.2.15.tar.gz
ARG SHA256=482be78d3444691781192468437a15b2ff7bf21c161ac2f84b91c7b0a257aff5

RUN curl -L -o lstags.tar.gz ${URL}\
  && echo "${SHA256} lstags.tar.gz" | sha256sum -c \
  && tar xfz lstags.tar.gz -C /usr/local/bin/ \
  && rm *.tar.gz

RUN mkdir /etc/lstags_default
COPY mirror.yaml /etc/lstags_default/mirror.yaml
VOLUME /etc/lstags

COPY docker-entrypoint.sh /
RUN chmod 755 /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
