#!/bin/bash

/etc/init.d/rsyslog start

if [ `ls /etc/lstags/ | wc -l` -eq 0 ]
then
  cp -r /etc/lstags_default/* /etc/lstags/
fi

if [ "${DOCKERMIRROR_DESTINATION_REGISTRY}" = "" ]
then
    echo "environemnt variable DOCKERMIRROR_DESTINATION_REGISTRY not set. Exit."
    exit 99
fi

if [ "${DOCKERMIRROR_INSECURE_REGISTRY_EX}" = "" ]
then
    export DOCKERMIRROR_INSECURE_REGISTRY_EX=localhost:5000
fi

if [ "${DOCKERMIRROR_CRON}" != "" ]
then
    crontime="${DOCKERMIRROR_CRON}"
else
    crontime="* */6 * * *"
fi
echo "@reboot root /usr/local/bin/lstags --push --yaml-config=/etc/lstags/mirror.yaml --insecure-registry-ex=${DOCKERMIRROR_INSECURE_REGISTRY_EX} --push-registry=${DOCKERMIRROR_DESTINATION_REGISTRY} 2>&1 | logger" > /etc/cron.d/lstags
echo "${crontime} root /usr/local/bin/lstags --push --yaml-config=/etc/lstags/mirror.yaml --insecure-registry-ex=${DOCKERMIRROR_INSECURE_REGISTRY_EX} --push-registry=${DOCKERMIRROR_DESTINATION_REGISTRY} 2>&1 | logger" >> /etc/cron.d/lstags
chmod 0644 /etc/cron.d/lstags

/etc/init.d/cron start

while [ ! -f /var/log/syslog ]
do
  sleep 1s
done

tail -f /var/log/syslog
