FROM opensuse:42.1

# rpm uses curl to import repository keys .........
RUN zypper -n install curl

# add repos
RUN \
	zypper -n ar -f http://download.opensuse.org/repositories/OBS:/Server:/2.7/openSUSE_42.1/ obs-2.7 && \
	zypper -n ar -f http://download.opensuse.org/repositories/devel:/languages:/python/openSUSE_Leap_42.2/ devel:languages:python && \
	rpm --import http://download.opensuse.org/repositories/OBS:/Server:/2.7/openSUSE_42.1/repodata/repomd.xml.key && \
	rpm --import http://download.opensuse.org/repositories/devel:/languages:/python/openSUSE_Leap_42.2/repodata/repomd.xml.key && \
	zypper -n ar -f http://download.opensuse.org/repositories/home:/mayerjosua:/OBS/openSUSE_Leap_15.1/ obs-2.10-arm-addon && \ 
	rpm --import http://download.opensuse.org/repositories/home:/mayerjosua:/OBS/openSUSE_Leap_15.1/repodata/repomd.xml.key && \
	:

# install packages
RUN zypper -n install supervisor obs-server obs-signd obs-source_service obs-api mysql-server

# mount persistent storage
VOLUME ["/srv/obs"]

# configure (/etc/sysconfig/obs-server)
ENV \
	OBS_API_AUTOSETUP=yes \
	OBS_RUN_DIR=/srv/obs/run \
	OBS_LOG_DIR=/srv/obs/log \
	OBS_BACKENDCODE_DIR=/usr/lib/obs/server/ \
	OBS_SIGND_GNUPG_HOME=/srv/obs/gnupg/ \
	OBS_SERVICE_DIR=/srv/obs/service \
	OBS_API_ROOT=/srv/www/obs/api \
	OBS_API_DELAYED_JOBS_NUM=3

COPY sign.conf /etc/sign.conf

# set up services
COPY supervisord.conf /etc/supervisord.d/obs.conf
RUN mkdir -p /var/run/supervisord

# public services on the network
EXPOSE 80 82 443

# start
CMD \
	set -x; \
	mkdir -p "$OBS_RUN_DIR" "$OBS_LOG_DIR" "$OBS_SERVICE_DIR"; \
	chown obsrun:obsrun "$OBS_RUN_DIR" "$OBS_LOG_DIR"; \
	chown obsservicerun:obsrun "$OBS_SERVICE_DIR"; \
	: \
	[ "$OBS_API_AUTOSETUP" != "yes" ] && /usr/lib/obs/server/setup-appliance.sh --non-interactive --setup-only; \
	: \
	OBS_SCHEDULER_ARCHITECTURES=`$OBS_BACKENDCODE_DIR/bs_admin --show-scheduler-architectures 2>/dev/null`; \
	for OBS_SCHEDULER_ARCHITECTURE in $OBS_SCHEDULER_ARCHITECTURES; do \
		printf "\n" >> /etc/supervisord.d/obs.conf; \
		printf "[program:bs_scheduler_%s]\n" $OBS_SCHEDULER_ARCHITECTURE >> /etc/supervisord.d/obs.conf; \
		printf "command=./bs_sched %s" $OBS_SCHEDULER_ARCHITECTURE >> /etc/supervisord.d/obs.conf; \
		printf " >> %s 2>&1\n" $OBS_LOG_DIR/scheduler_$OBS_SCHEDULER_ARCHITECTURE.log >> /etc/supervisord.d/obs.conf; \
		printf "user=obsrun\n" >> /etc/supervisord.d/obs.conf; \
	done; \
	: \
	/usr/bin/supervisord; \
	:
