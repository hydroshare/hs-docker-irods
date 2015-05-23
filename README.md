# hs-docker-irods

iRODS v4.1.0 in a docker container.

- ICAT_SERVER: **irods-icat-4.1.0-64bit-centos6.rpm**
- DATABASE_PLUGIN: **irods-database-plugin-postgres93-1.5-centos6.rpm**
- DEVELOPMENT_TOOLS: **irods-dev-4.1.0-64bit-centos6.rpm**
- RUNTIME_LIBRARIES: **irods-runtime-4.1.0-64bit-centos6.rpm**
- MICROSERVICE_PLUGIN: **irods-microservice-plugins-curl-1.1-centos6.rpm**

**TL;DR**

Requires Docker version 1.3.2 or greater

1. Clone the hs-docker-irods project into you home directory, fetch the pre-built images or build from source, and run the `run-hs-docker-irods.sh` script.

    ```
$ git clone https://github.com/hydroshare/hs-docker-irods.git
$ cd hs-docker-irods
$ ./run-hs-docker-irods.sh HOST_IP_ADDRESS
```
2. Verify installation using iDrop Web at **http://HOST_IP_ADRESS:8080/idrop-web2/**
    - User Name: **hsproxy**
    - Password: **proxywater1**
3. HydroShare/iDrop Configuration
    - HYDROSHARE_IRODS_RESOURCE: **hydrodevResc**
    - HYDORSHARE_IRODS_ZONE: **hydrodevZone**
    - HYDROSHARE_IRODS_USERNAME: **hsproxy**
    - HYDROSHARE_IRODS_AUTH: **proxywater1**
4. iRODS configuration
    - SERVICE_ACCT_USERNAME: **irods**
    - SERVICE_ACCT_GROUP: **irods**
    - IRODS_ZONE: **hydrodevZone**
    - IRODS_PORT: **1247**
    - RANGE_BEGIN: **20000**
    - RANGE_END: **20199**
    - VAULT_DIRECTORY: **/var/lib/irods/iRODS/Vault**
    - ZONE_KEY: **TEMPORARY_zone_key**
    - NEGOTIATION_KEY: **TEMPORARY_32byte_negotiation_key**
    - CONTROL_PLANE_PORT: **1248**
    - CONTROL_PLANE_KEY: **TEMPORARY__32byte_ctrl_plane_key**
    - SCHEMA_VALIDATION_BASE_URI: **https://schemas.irods.org/configuration**
    - ADMINISTRATOR_USERNAME: **rods**
    - ADMINISTRATOR_PASSWORD: **rods**
    - HOSTNAME_OR_IP: **hs-irods-db**
    - DATABASE_PORT: **5432**
    - DATABASE_NAME: **ICAT**
    - DATABASE_USER: **irods**
    - DATABASE_PASSWORD: **irods**
