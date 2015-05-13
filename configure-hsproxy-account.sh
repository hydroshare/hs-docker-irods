#!/bin/bash

CONFIG_FILE=$1

# read hsproxy-config.yaml into environment
sed -e "s/:[^:\/\/]/=/g;s/$//g;s/ *=/=/g" ${CONFIG_FILE} > hsproxy-config.sh
while read line; do export $line; done < <(cat hsproxy-config.sh)
# read irods-config.yaml into environment
sed -e "s/:[^:\/\/]/=/g;s/$//g;s/ *=/=/g" irods-config.yaml > irods-config.sh
while read line; do export $line; done < <(cat irods-config.sh)

#MYACCTNAME=`echo "${IRODS_SERVICE_ACCOUNT_NAME}" | sed -e "s/\///g"`

# check zone name
CHECK_IRODS_ZONE=$(docker exec -ti hs-irods-icat sudo -u ${SERVICE_ACCT_USERNAME} iadmin lz)

if [ "$CHECK_IRODS_ZONE" != "$HYDORSHARE_IRODS_ZONE" ]; then
    echo "*** Found Zone: ${HYDORSHARE_IRODS_ZONE} ***"
    echo "*** Please change the file: irods-config.yml and rerun script "
    echo "  IRODS_ZONE: ${HYDORSHARE_IRODS_ZONE} ***"
    echo "";
else
    echo "*** Found Zone: ${HYDORSHARE_IRODS_ZONE} ***";
fi

# check resource name
CHECK_IRODS_RESOURCE=$(docker exec -ti hs-irods-icat sudo -u irods iadmin lr | grep ${HYDROSHARE_IRODS_RESOURCE})

if [ -z "$CHECK_IRODS_RESOURCE" ]; then
    echo "*** Create Resource: ${HYDROSHARE_IRODS_RESOURCE} ***"
    docker exec -ti hs-irods-icat sudo -u ${SERVICE_ACCT_USERNAME} iadmin mkresc ${HYDROSHARE_IRODS_RESOURCE} \
        'unixfilesystem' localhost:${VAULT_DIRECTORY};
else
    echo "*** Found Resource: ${HYDROSHARE_IRODS_RESOURCE} ***";
fi

# check user name
CHECK_IRODS_USER=$(docker exec -ti hs-irods-icat sudo -u irods iadmin lu | grep ${HYDROSHARE_IRODS_USERNAME})
if [ -z "$CHECK_IRODS_USER" ]; then
    echo "*** Create User: ${HYDROSHARE_IRODS_USERNAME} ***"
    docker exec -ti hs-irods-icat sudo -u ${SERVICE_ACCT_USERNAME} iadmin mkuser ${HYDROSHARE_IRODS_USERNAME} rodsuser
    docker exec -ti hs-irods-icat sudo -u ${SERVICE_ACCT_USERNAME} iadmin moduser ${HYDROSHARE_IRODS_USERNAME} password ${HYDROSHARE_IRODS_AUTH};
else
    echo "*** Found User: ${HYDROSHARE_IRODS_USERNAME} ***";
fi