#!/bin/bash

CONFIG_FILE=$1

# read hsproxy-config.yaml into environment
sed -e "s/:[^:\/\/]/=/g;s/$//g;s/ *=/=/g" ${CONFIG_FILE} > hsproxy-config.sh
while read line; do export $line; done < <(cat hsproxy-config.sh)

#MYACCTNAME=`echo "${IRODS_SERVICE_ACCOUNT_NAME}" | sed -e "s/\///g"`

# check zone name
ZONE_NAME=$(docker exec -ti hs-irods-icat sudo -u irods iadmin lz)
ZONE_NAME=${ZONE_NAME%?}
echo "*** ZONE_NAME = ${ZONE_NAME} ***"
#ZONE_NAME=$(echo ${CURRENT_ZONE//[[:blank:]]/})
HAS_ZONE=$(echo ${ZONE_NAME} | grep ${HYDORSHARE_IRODS_ZONE})
echo "*** HAS_ZONE = ${HAS_ZONE} ***"
if [ -z ${HAS_ZONE} ]; then
    echo "*** ${ZONE_NAME} ***"
    echo "*** ${HYDORSHARE_IRODS_ZONE} ***"
    docker exec -it hs-irods-icat sudo -u irods iadmin modzone ${ZONE_NAME} name ${HYDORSHARE_IRODS_ZONE};
else
    echo "*** Found Zone: $(ZONE_NAME) ***";
fi

# check resource name
HAS_RESOURCE=$(docker exec -ti hs-irods-icat sudo -u irods iadmin lr | grep ${HYDROSHARE_IRODS_RESOURCE})
if [ -z ${HAS_RESOURCE} ]; then
    echo "*** ${HYDROSHARE_IRODS_RESOURCE} ***";
else
    echo "Yep";
fi

# check user name
HAS_USER=$(docker exec -ti hs-irods-icat sudo -u irods iadmin lu | grep ${HYDROSHARE_IRODS_USERNAME})
if [ -z ${HAS_USER} ]; then
    echo "*** ${HYDROSHARE_IRODS_USERNAME} ***";
else
    echo "Yep";
fi