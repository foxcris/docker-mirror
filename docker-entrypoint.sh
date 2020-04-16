#!/bin/bash

/etc/init.d/rsyslog start

if [ ! -f /etc/skopeo/mirror.yaml ] || [ `/etc/skopeo/mirror.yaml | wc -l` -eq 0 ]
then
  cp -r /etc/skopeo_default/mirror.yaml /etc/skopeo/mirror.yaml
fi

if [ "${DOCKERMIRROR_CONFIGFILE}" = "" ]
then
    DOCKERMIRROR_CONFIGFILE="/etc/skopeo/mirror.yaml"
fi

if [ "${DOCKERMIRROR_DESTINATION_REGISTRY}" = "" ]
then
    echo "environemnt variable DOCKERMIRROR_DESTINATION_REGISTRY not set. Exit."
    exit 99
fi

insecure_regestry=""
if [ "${DOCKERMIRROR_DESTINATION_INSECURE_REGISTRY}" = "true" ]
then
    insecure_regestry='--dest-tls-verify=false'
fi

if [ "${DOCKERMIRROR_CRON}" != "" ]
then
    crontime="${DOCKERMIRROR_CRON}"
else
    crontime="* */6 * * *"
fi

echo "@reboot root /usr/bin/skopeo sync ${insecure_regestry} --src yaml --dest docker ${DOCKERMIRROR_CONFIGFILE} ${DOCKERMIRROR_DESTINATION_REGISTRY} 2>&1 | logger" > /etc/cron.d/skopeo
echo "${crontime} root /usr/bin/skopeo sync ${insecure_regestry} --src yaml --dest docker ${DOCKERMIRROR_CONFIGFILE} ${DOCKERMIRROR_DESTINATION_REGISTRY} 2>&1 | logger" >> /etc/cron.d/skopeo
chmod 0644 /etc/cron.d/skopeo

/etc/init.d/cron start

while [ ! -f /var/log/syslog ]
do
  sleep 1s
done

tail -f /var/log/syslog
