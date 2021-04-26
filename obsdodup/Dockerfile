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
RUN zypper -n install obs-server
RUN zypper -n install gzip xz

RUN zypper -n install patch
COPY *.patch /
RUN set -e; \
	patch -p0 < debug-flock.patch; \
	:

# mount persistent storage
VOLUME ["/srv/obs"]

# create runtime directories
RUN mkdir -p /srv/obs

# entrypoint
COPY entry.sh /entry.sh
ENTRYPOINT ["/bin/bash", "/entry.sh"]
CMD []
