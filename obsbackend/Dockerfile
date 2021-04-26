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

# create system users here *before* zypper to enforce static uid and gid
RUN set -e; \
	groupadd -r -g 482 obsrun; \
	useradd -r -g 482 -u 480 -d /usr/lib/obs -s /sbin/nologin -c 'User for the build service source service' obsservicerun; \
	useradd -r -g 482 -u 482 -d /usr/lib/obs -s /sbin/nologin -c 'User for build service backend' obsrun; \
	:

# install packages
RUN zypper -n install supervisor obs-server obs-signd obs-source_service

# mount persistent storage
VOLUME ["/srv/obs"]

# configure
COPY sign.conf /etc/sign.conf

# create runtime directories
RUN mkdir -p /srv/obs

# prestart script
COPY setup.sh /setup.sh

# set up services
COPY supervisord.conf /etc/supervisord.d/obs.conf
RUN mkdir -p /var/run/supervisord

# public services on the network
# source-server: 5352
# repo-server: 5252
EXPOSE 5252 5352

# start
CMD \
	set -e; \
	set -x; \
	find /srv/obs/; \
	/bin/bash /setup.sh; \
	/usr/bin/supervisord; \
	:
