#!/bin/bash

# run-hs-docker-irods.sh
# Author: Michael Stealey <michael.j.stealey@gmail.com>

echo "*** RUN SCRIPT appstack-run-irods.sh ***"

IDROP_IP_ADDR=$1
IDROP_IRODS_SECRETS=$2
APPSTACK_PATH=${PWD}'/appstack'

# move config files into place
echo "*** Copy idrop-config.yaml and irods-config.yaml into place ***"
yes | cp irods-config.yaml appstack/setup-irods-icat-v4.1.0/irods-config.yaml
yes | cp idrop-config.yaml appstack/idrop-web-v2.1.0/idrop-config.yaml

echo "*** update github submodules ***"
git submodule init && git submodule update

# build data image
echo "*** docker build -t appstack-data . ***"
docker build -t appstack-data .

# build docker appstack images
${APPSTACK_PATH}/appstack-build.sh ${APPSTACK_PATH}

# Launch data volume as docker container data
echo "*** docker run appstack-data as data ***"
docker run -d --name hs-irods-data -v /var/lib/pgsql/9.3/data -v /srv/irods:/var/lib/irods -v /etc/irods \
    -v /opt/java -v /opt/tomcat -v /srv/log:/var/log -v /root/.secret -it appstack-data
sleep 1s

# Setup postgreql database
echo "*** docker run setup-postgresql-v9.3.6 ***"
docker run --rm --volumes-from hs-irods-data -it setup-postgresql-v9.3.6
sleep 1s

# Launch postgres database as docker container db
echo "*** docker run postgresql-v9.3.6 as db ***"
docker run -u postgres -d --name hs-irods-db --volumes-from hs-irods-data postgresql-v9.3.6
sleep 3s

# Setup irods environment
echo "*** docker run setup-irods-icat-v4.1.0 ***"
docker run --rm --volumes-from hs-irods-data --link hs-irods-db:db -it setup-irods-icat-v4.1.0
sleep 3s

# Lauch irods environment as docker container icat
echo "*** docker run irods-icat-v4.1.0 as hs-irods-icat ***"
docker run -d --name hs-irods-icat --volumes-from hs-irods-data --link hs-irods-db:db irods-icat-v4.1.0

# Check for iRODS hsproxy user and configure if it does not exist
echo "*** setup hsproxy if it does not exist ***"
./configure-hsproxy-account.sh hsproxy-config.sh

# Setup tomcat for iDrop Web
echo "*** docker run setup-tomcat-v8.0.22 ***"
docker run --rm --volumes-from hs-irods-data -it setup-tomcat-v8.0.22

# Launch iDrop Web2
echo "*** docker run idrop-web-v2.1.0 as hs-irods-idrop ***"
docker run -d --name hs-irods-idrop --volumes-from hs-irods-data -p 8080:8080 --link hs-irods-icat:hs-irods-icat \
    idrop-web-v2.1.0 ${IDROP_IP_ADDR} ${IDROP_IRODS_SECRETS}

echo "*** FINISHED SCRIPT appstack-run-irods.sh ***"