#!/bin/bash

# create runtime directories in storage volume, if missing
mkdir -p /srv/obs/{gnupg,log,run,service}
chown obsrun:obsrun /srv/obs/{gnupg,log,run}
chown obsservicerun:obsrun /srv/obs/service

# patch BSConfig.pm
# allow any host to access core services (security should be handled by the container host)
bsconfig=/usr/lib/obs/server/BSConfig.pm
printf "\$ipaccess->{'%s'} = 'rw'\n" ".*" >> $bsconfig
# TODO: use fqdn of frontend host here!

# start a scheduler for every enabled architecture
# TODO: do this statically?
# perhaps try to start them all, and retry every 10 minutes
OBS_SCHEDULER_ARCHITECTURES=`$OBS_BACKENDCODE_DIR/bs_admin --show-scheduler-architectures 2>/dev/null`
for OBS_SCHEDULER_ARCHITECTURE in $OBS_SCHEDULER_ARCHITECTURES; do
	printf "\n" >> /etc/supervisord.d/obs.conf
	printf "[program:bs_scheduler_%s]\n" $OBS_SCHEDULER_ARCHITECTURE >> /etc/supervisord.d/obs.conf
	printf "command=./bs_sched %s" $OBS_SCHEDULER_ARCHITECTURE >> /etc/supervisord.d/obs.conf
	printf " >> %s 2>&1\n" $OBS_LOG_DIR/scheduler_$OBS_SCHEDULER_ARCHITECTURE.log >> /etc/supervisord.d/obs.conf
	printf "user=obsrun\n" >> /etc/supervisord.d/obs.conf
done
