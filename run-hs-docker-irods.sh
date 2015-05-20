#!/bin/bash

# run-hs-docker-irods.sh
# Author: Michael Stealey <michael.j.stealey@gmail.com>

echo "*** RUN SCRIPT appstack-run-irods.sh ***"

# Configuration Variables - User defined
IDROP_IP_ADDR=$1
IDROP_CONFIG_FILE='idrop-config.yaml'
IRODS_CONFIG_FILE='irods-config.yaml'
PROXY_CONFIG_FILE='hs-irods-user-config.yaml'

# Configuration Variables - Internal
APPSTACK_PATH=${PWD}'/appstack'
APPSTACK_DATA_IMG='appstack-data'
APPSTACK_DATA='hs-irods-data'
APPSTACK_POSTGRESQL='hs-irods-db'
APPSTACK_IRODS='hs-irods-icat'
APPSTACK_IDROP='hs-irods-idrop'

# move config files into place
echo "*** Copy ${IRODS_CONFIG_FILE} and ${IDROP_CONFIG_FILE} into place ***"
yes | cp ${IRODS_CONFIG_FILE} appstack/setup-irods-icat-v4.1.0/${IRODS_CONFIG_FILE}
yes | cp ${IDROP_CONFIG_FILE} appstack/idrop-web-v2.1.0/${IDROP_CONFIG_FILE}

echo "*** update github submodules ***"
git submodule init && git submodule update

# build data image
CHECK_DATA_IMG=`docker images | tr -s ' ' | cut -d ' ' -f 1 | grep ${APPSTACK_DATA_IMG}`
if [[ -z "${CHECK_DATA_IMG}" ]]; then
    echo "*** docker build -t ${APPSTACK_DATA_IMG} . ***"
    docker build -t ${APPSTACK_DATA_IMG} .;
else
    echo "*** IMG: ${APPSTACK_DATA_IMG} already exists ***";
fi

# build docker appstack images
${APPSTACK_PATH}/appstack-build.sh ${APPSTACK_PATH}

# Launch data volume as docker container data
CHECK_DATA_CID=`docker ps -a | tr -s ' ' | grep ${APPSTACK_DATA} | cut -d ' ' -f 1`
if [[ -z "${CHECK_DATA_CID}" ]]; then
    echo "*** docker run ${APPSTACK_DATA_IMG} as ${APPSTACK_DATA} ***"
    docker run -d --name ${APPSTACK_DATA} -v /srv/pgsql:/var/lib/pgsql/9.3/data -v /srv/irods:/var/lib/irods \
        -v /srv/etc_irods:/etc/irods -v /opt/java -v /opt/tomcat -v /srv/log:/var/log -v /root/.secret -it ${APPSTACK_DATA_IMG}
    sleep 3s;
else
    CHECK_DATA_CID=`docker ps | tr -s ' ' | grep ${APPSTACK_DATA} | cut -d ' ' -f 1`
    if [[ -z "${CHECK_DATA_CID}" ]]; then
        echo "*** CONTAINER: ${APPSTACK_DATA} already exists but is not running, restarting the container ***"
        docker start ${APPSTACK_DATA}
        sleep 3s;
    else
        echo "*** CONTAINER: ${APPSTACK_DATA} already exists as CID: ${CHECK_DATA_CID}, container is already running ***";
    fi
fi

# Setup postgreql database
CHECK_POSTGRESQL_CID=`docker ps -a | tr -s ' ' | grep ${APPSTACK_POSTGRESQL} | cut -d ' ' -f 1`
CHECK_POSTGRESQL_DIR=`docker exec -ti ${APPSTACK_DATA} ls /var/lib/pgsql/9.3/data/`
if [[ -z "${CHECK_POSTGRESQL_CID}" ]] && [[ -z "${CHECK_POSTGRESQL_DIR}" ]]; then
    echo "*** docker run setup-postgresql-v9.3.6 ***"
    docker run --rm --volumes-from ${APPSTACK_DATA} -it setup-postgresql-v9.3.6
    sleep 3s;
else
    echo "*** SETUP: ${APPSTACK_POSTGRESQL} already exists or /var/lib/posgql/9.3/data/ has already been populated ***";
fi

# Launch postgres database as docker container db
CHECK_POSTGRESQL_CID=`docker ps -a | tr -s ' ' | grep ${APPSTACK_POSTGRESQL} | cut -d ' ' -f 1`
if [[ -z "${CHECK_POSTGRESQL_CID}" ]]; then
    echo "*** docker run postgresql-v9.3.6 as ${APPSTACK_POSTGRESQL} ***"
    docker run -u postgres -d --name ${APPSTACK_POSTGRESQL} --volumes-from ${APPSTACK_DATA} postgresql-v9.3.6
    sleep 3s;
else
    CHECK_POSTGRESQL_CID=`docker ps | tr -s ' ' | grep ${APPSTACK_POSTGRESQL} | cut -d ' ' -f 1`
    if [[ -z "${CHECK_POSTGRESQL_CID}" ]]; then
        echo "*** CONTAINER: ${APPSTACK_POSTGRESQL} already exists but is not running, restarting the container ***"
        docker start ${APPSTACK_POSTGRESQL}
        sleep 3s;
    else
        echo "*** CONTAINER: ${APPSTACK_POSTGRESQL} already exists as CID: ${CHECK_POSTGRESQL_CID}, container already running ***";
    fi
fi

# Setup irods environment
CHECK_IRODS_CID=`docker ps -a | tr -s ' ' | grep ${APPSTACK_IRODS} | cut -d ' ' -f 1`
CHECK_IRODS_DIR=`docker exec -ti hs-irods-data ls /var/lib/irods/`
if [[ -z "${CHECK_IRODS_CID}" ]] && [[ -z "${CHECK_IRODS_DIR}" ]]; then
    echo "*** docker run setup-irods-icat-v4.1.0 ***"
    docker run --rm --volumes-from ${APPSTACK_DATA} --link ${APPSTACK_POSTGRESQL}:${APPSTACK_POSTGRESQL} -it setup-irods-icat-v4.1.0
    sleep 3s
else
    echo "*** SETUP: ${APPSTACK_IRODS} already exists or /var/lib/irods/ has already been populated ***";
fi

# Lauch irods environment as docker container icat
CHECK_IRODS_CID=`docker ps -a | tr -s ' ' | grep ${APPSTACK_IRODS} | cut -d ' ' -f 1`
if [[ -z "${CHECK_IRODS_CID}" ]]; then
    echo "*** docker run irods-icat-v4.1.0 as ${APPSTACK_IRODS} ***"
    docker run -d --name ${APPSTACK_IRODS} --volumes-from ${APPSTACK_DATA} --link ${APPSTACK_POSTGRESQL}:${APPSTACK_POSTGRESQL} irods-icat-v4.1.0
    sleep 3s;
else
    CHECK_IRODS_CID=`docker ps | tr -s ' ' | grep ${APPSTACK_IRODS} | cut -d ' ' -f 1`
    if [[ -z "${CHECK_IRODS_CID}" ]]; then
        echo "*** CONTAINER: ${APPSTACK_IRODS} already exists but is not running, restarting the container ***"
        docker start ${APPSTACK_IRODS}
        sleep 3s;
    else
        echo "*** CONTAINER: ${APPSTACK_IRODS} already exists as CID: ${CHECK_IRODS_CID}, container already running ***";
    fi
fi

# Check for iRODS hsproxy user and configure if it does not exist
echo "*** setup hsproxy if it does not exist ***"
./configure-hs-irods-user-account.sh ${PROXY_CONFIG_FILE}

# Setup tomcat for iDrop Web
CHECK_IDROP_CID=`docker ps -a | tr -s ' ' | grep ${APPSTACK_IDROP} | cut -d ' ' -f 1`
CHECK_IDROP_DIR=`docker exec -ti hs-irods-data ls /opt/tomcat/`
if [[ -z "${CHECK_IDROP_CID}" ]] && [[ -z "${CHECK_IDROP_DIR}" ]]; then
    echo "*** docker run setup-tomcat-v8.0.22 ***"
    docker run --rm --volumes-from ${APPSTACK_DATA} -it setup-tomcat-v8.0.22
    sleep 3s;
else
    echo "*** SETUP: ${APPSTACK_IDROP} already exists or /opt/tomat/ has already been populated ***";
fi

# Launch iDrop Web2
CHECK_IDROP_CID=`docker ps -a | tr -s ' ' | grep ${APPSTACK_IDROP} | cut -d ' ' -f 1`
if [[ -z "${CHECK_IDROP_CID}" ]]; then
    echo "*** docker run idrop-web-v2.1.0 as ${APPSTACK_IDROP} ***"
    docker run -d --name ${APPSTACK_IDROP} --volumes-from ${APPSTACK_DATA} -p 8080:8080 --link ${APPSTACK_IRODS}:${APPSTACK_IRODS} \
        idrop-web-v2.1.0 ${IDROP_IP_ADDR} ${IDROP_CONFIG_FILE}
    sleep 3s;
else
    CHECK_IDROP_CID=`docker ps | tr -s ' ' | grep ${APPSTACK_IDROP} | cut -d ' ' -f 1`
    if [[ -z "${CHECK_IDROP_CID}" ]]; then
        echo "*** CONTAINER: ${APPSTACK_IDROP} already exists but is not running, restarting the container ***"
        docker start ${APPSTACK_IDROP}
        sleep 3s;
    else
        echo "*** CONTAINER: ${APPSTACK_IDROP} already exists as CID: ${CHECK_IDROP_CID}, container already running ***";
    fi
fi

echo "*** FINISHED SCRIPT appstack-run-irods.sh ***"
exit;
