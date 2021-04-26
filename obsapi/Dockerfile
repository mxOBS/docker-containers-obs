FROM opensuse/leap:15.1

# rpm uses curl to import repository keys .........
RUN zypper -n install curl

# add repos
RUN \
	zypper -n ar -f http://download.opensuse.org/repositories/OBS:/Server:/2.10/openSUSE_15.1 obs-2.10 && \
	rpm --import http://download.opensuse.org/repositories/OBS:/Server:/2.10/openSUSE_15.1/repodata/repomd.xml.key && \
	zypper -n ar -f https://repo.solid-build.xyz/obs/OBS:/Server:/2.10/openSUSE_Leap_15.1/ obs-2.10-arm && \
	rpm --import https://repo.solid-build.xyz/obs/OBS:/Server:/2.10/openSUSE_Leap_15.1/repodata/repomd.xml.key && \
	zypper -n ar -f http://download.opensuse.org/repositories/home:/mayerjosua:/OBS/openSUSE_Leap_15.1/ obs-2.10-arm-addon && \ 
	rpm --import http://download.opensuse.org/repositories/home:/mayerjosua:/OBS/openSUSE_Leap_15.1/repodata/repomd.xml.key && \
	:

# create system users here *before* zypper to enforce static uid and gid
RUN set -e; \
	groupadd -r -g 482 obsrun; \
	useradd -r -g 482 -u 480 -d /usr/lib/obs -s /sbin/nologin -c 'User for the build service source service' obsservicerun; \
	useradd -r -g 482 -u 482 -d /usr/lib/obs -s /sbin/nologin -c 'User for build service backend' obsrun; \
	:

# install packages
RUN zypper -n install supervisor python2-setuptools
RUN zypper -n install obs-api net-tools bind-utils

# mount persistent storage
VOLUME ["/srv/obs"]

# configure (/etc/sysconfig/obs-server)
ENV \
	OBS_BASE_DIR=/srv/obs \
	OBS_API_ROOT=/srv/www/obs/api \
	OBS_API_DELAYED_JOBS_NUM=3

# create runtime directories
RUN \
	mkdir -p $OBS_BASE_DIR $OBS_BASE_DIR/certs

# prestart script
COPY setup.sh /setup.sh
COPY wait-for-it.sh /wait-for-it.sh

# set up services
COPY supervisord.conf /etc/supervisord.d/obs.conf
RUN mkdir -p /var/run/supervisord

# public services on the network
EXPOSE 80 82 443

# start
CMD \
	set -e; \
	set -x; \
	:; \
	/bin/bash /setup.sh; \
	:; \
	/usr/bin/supervisord; \
	:
