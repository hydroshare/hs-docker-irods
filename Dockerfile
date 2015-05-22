FROM centos:centos6.6
MAINTAINER Michael Stealey <michael.j.stealey@gmail.com>

RUN yum install -y wget
RUN wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN rpm -Uvh epel-release-6*.rpm

ADD config-files /config-files

VOLUME ["/conf", "/var/log", "/var/backup", "/root/.secret", \
"/opt/java", "/opt/tomcat", \
"/var/lib/pgsql/9.3/data", \
"/var/lib/irods", "/etc/irods"]

# Keep container from shutting down until explicitly stopped
ENTRYPOINT ["/usr/bin/tail"]
CMD ["-f", "/dev/null"]