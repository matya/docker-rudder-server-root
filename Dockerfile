FROM phusion/baseimage:latest
MAINTAINER Janos Mattyasovszky <mail@matya.hu>

ENV \
	DEBIAN_FRONTEND=noninteractive 
RUN \
	apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 474A19E8 && \
	{ echo "deb http://www.rudder-project.org/apt-3.0/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/rudder.list; } && \
	apt-get -y update 

RUN \
	apt-get -y --no-install-recommends install apache2 apache2-utils libapache2-mod-wsgi postgresql postgresql-client ldap-utils rsyslog rsyslog-pgsql openjdk-7-jre-headless git-core

RUN \
	apt-get -y --no-install-recommends install rudder-inventory-ldap && \
	/etc/init.d/rudder-slapd start && \
	/etc/init.d/postgresql start && \
	apt-get -y --no-install-recommends install rudder-server-root && \
	SUBNET=$( ip ro sh dev eth0 | grep 'scope link' | cut -f1 -d' ' ) && \
	{ printf "${SUBNET}\nno\n\n" | /opt/rudder/bin/rudder-init; } && \
	/etc/init.d/rudder-slapd stop && \
	bzip2 -9 /var/rudder/ldap/backup/openldap-data-*.ldif && \
	/etc/init.d/postgresql stop 

RUN \
	rm -rf /etc/service/* && \
	c=0 && \
	for srv in rsyslog cron postgresql rudder-slapd rudder-jetty apache2; do \
		c=$((c+1)) && \
		myname=$(printf "%02i_%s" "$c" "$srv") && \
		printf "#!/bin/bash\nexec /etc/init.d/%s start\n" "$srv" > /etc/my_init.d/${myname}; \
	done && \
	chmod +x /etc/my_init.d/* 

EXPOSE 80 443 5309

