FROM debian:stable

# install packages
ENV DEBIAN_FRONTEND noninteractive

COPY ./sources.list /etc/apt/sources.list

RUN apt-get update &&  apt-get -y dist-upgrade && \
    apt-get -y --force-yes install openssl dpkg-dev debhelper syslog-ng-core syslog-ng && \
    apt-get -y build-dep pure-ftpd-mysql

RUN mkdir /ftpdata && \
    mkdir /tmp/pure-ftpd-mysql

WORKDIR /tmp/pure-ftpd-mysql

RUN apt-get source pure-ftpd-mysql && \
    cd pure-ftpd-* && \
    sed -i '/^optflags=/ s/$/ --without-capabilities/g' ./debian/rules && \
    dpkg-buildpackage -b -uc 

RUN ls -lah .

RUN dpkg -i ./pure-ftpd-common*.deb

RUN apt-get -y install openbsd-inetd default-mysql-client systemctl rsyslog

RUN dpkg -i ./pure-ftpd-mysql*.deb

RUN apt-mark hold pure-ftpd pure-ftpd-mysql pure-ftpd-common

# add docker user and group
RUN groupadd -g 999 docker
RUN useradd -u 111 -g 999 -d /dev/null -s /usr/sbin/nologin docker
RUN chown -R docker:docker /ftpdata

# cleanup
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

RUN systemctl start rsyslog

# expose important ports
EXPOSE 20 21 30000-30100

CMD ["/usr/sbin/pure-ftpd-mysql"]