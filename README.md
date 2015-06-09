# hs-docker-irods

A dockerized version of iRODS v4.1.x using PostgreSQL v9.3.6 as the iCAT database.

To overcome the ephemeral nature of docker containers this project has been structured to make use of a centralized data container to share and persist data volumes between the running docker containers and the host. In this way the docker containers can come into or out of existence and attach to a previously known state based on the contents of the shared volumes. The iRODS iCAT database and any added data files will remain intact even if the running containers are stopped, removed or have their images destroyed entirely.

---

### How this works

1. A data container is created for the sole purpose of sharing information between other docker containers and the host
    - Create volumes to share with other containers: 
    
    ```
    VOLUME ["/conf", "/var/log", "/var/backup", "/root/.secret", \
"/opt/java", "/opt/tomcat", \
"/var/lib/pgsql/9.3/data", \
"/var/lib/irods", "/etc/irods"]
```
    - Mount volumes as shared directories with the host: 
    
    ```
    docker run -d --name ${APPSTACK_DATA} -v /srv/conf:/conf -v /srv/log:/var/log -v /srv/backup:/var/backup \
        -v /srv/java:/opt/java -v /srv/tomcat:/opt/tomcat \
        -v /srv/pgsql:/var/lib/pgsql/9.3/data \
        -v /srv/irods:/var/lib/irods -v /srv/etc_irods:/etc/irods \
        -v /srv/.secret:/root/.secret \
        -ti ${APPSTACK_DATA_IMG}
``` 
2. A PostgreSQL database is added in two phases
    - Setup - Configure and install the required PostgreSQL files onto the shared data volumes provided by the data container.
    - Run - Stand up a light weight container and connect to the pre-configured PostgreSQL instance as defined in the shared data volumes provided by the data container.
3. An iRODS installation is added in two phases
    - Setup - Configure and install the required iRODS files onto the shared data volumes provided by the data container.
    - Run - Stand up a light weight contianer and connect to the pre-configured iRODS instance as defined in the shared data volumes. Certain group and user checks are also performed. 
4. An iDrop Web viewer is added in two phases
    - Setup - Configure and install the required tomcat and java files onto the shared data volumes provided by the data container.
    - Run - Stand up a light weight container and connect to the pre-configured tomcat and java files as defined in the shared data volumes provided by the data container.
    
---

### How to use

1. Ensure you have a version of docker that can execute `docker exec`. This would be docker version 1.3 or later.
2. Configure the `irods-config.yaml`, `rodsuser-config.yaml` and `idrop-config.yaml` files
3. Run the script `run-docker-irods.sh HOST_IP_ADDR`, where **HOST_IP_ADDRESS** is the IP of your host you are running on (same as the host you use for viewing the hydroshare application in a browser). 
4. Check [http://DOCKER_IP_ADDR:8080/idrop-web2/](http://HOST_IP_ADDR:8080/idrop-web2/), and Sign in as the user defined in `rodsuser-config.yaml`

### Configure

The first time the script is run it will build the required images to setup and run iRODS with PostgreSQL using the attributes defined in `config-files/irods-config.yaml` and `config-files/rodsuser-config.yaml`. You will want to define the attributes for your environment prior to running the script for the first time. 

The iRODS administrative information as well as one additional standard **rodsuser** can be defined in the config files. The default settings for each of these files is shown below.

**irods-config.yaml**

```
SERVICE_ACCT_USERNAME: irods
SERVICE_ACCT_GROUP: irods
IRODS_ZONE: dockerZone
IRODS_PORT: 1247
RANGE_BEGIN: 20000
RANGE_END: 20199
VAULT_DIRECTORY: /var/lib/irods/iRODS/Vault
ZONE_KEY: TEMPORARY_zone_key
NEGOTIATION_KEY: TEMPORARY_32byte_negotiation_key
CONTROL_PLANE_PORT: 1248
CONTROL_PLANE_KEY: TEMPORARY__32byte_ctrl_plane_key
SCHEMA_VALIDATION_BASE_URI: https://schemas.irods.org/configuration
ADMINISTRATOR_USERNAME: rods
ADMINISTRATOR_PASSWORD: rods
HOSTNAME_OR_IP: irods-db
DATABASE_PORT: 5432
DATABASE_NAME: ICAT
DATABASE_USER: irods
DATABASE_PASSWORD: irods
```
**rodsuser-config.yaml**

```
RODSUSER_IRODS_RESOURCE: dockerResc
RODSUSER_IRODS_ZONE: dockerZone
RODSUSER_IRODS_USERNAME: docker-irods
RODSUSER_IRODS_AUTH: docker-irods
```

### Run

Once you've configured the `irods-config.yaml` and `rodsuser-config.yaml` files you only need to run the `run-docker-irods.sh` script. The information you provided in the config files will be used to setup and run the iRODS environment.

**Example**

```
$ ./run-docker-irods.sh
*** RUN SCRIPT run-docker-irods.sh ***
*** update github submodules ***
...
Starting iRODS server...
Confirming catalog_schema_version... Success
Validating [/var/lib/irods/.irods/irods_environment.json]... Success
Validating [/etc/irods/server_config.json]... Success
Validating [/etc/irods/hosts_config.json]... Success
Validating [/etc/irods/host_access_control_config.json]... Success
Validating [/etc/irods/database_config.json]... Success
*** Create User: docker-irods ***
*** FINISHED SCRIPT run-docker-irods.sh ***
```

If run using the default configuration you would be able to verify your install by using `docker exec` to get into the running **irods-icat** container and check the status using the **irods** administrative user.

```
$ docker exec -ti irods-icat /bin/bash
[root@71aaf7becbd9 scripts]# su - irods

-bash-4.1$ iadmin lz
hydrodevZone

-bash-4.1$ iadmin lr
bundleResc
demoResc
hydrodevResc

-bash-4.1$ iadmin lu
rods#hydrodevZone
hsproxy#hydrodevZone
```
From here you could also perform any other standard iRODS iCommands or modifications to your running iRODS environment.

### HydroShare usage

The HydroShare application will not run properly unless there is an already running iRODS installation for it to connect to. The iRODS settings that HydroShare will use are found in the **local_settings.py** file.

Update the **local_settings.py** in the `hydroshare/hydroshare` directory with the appropriate value for `HS_IRODS_ICAT_IP`. To find your `HS_IRODS_ICAT_IP` you need to use `docker inspect`.

**Example**

```
$ docker inspect irods-icat | grep IPAddress
        "IPAddress": "172.17.0.100",   
```
You will use the value **172.17.0.100** as the value for `HS_IRODS_ICAT_IP` in the local_settings.py file


```
# iRODS proxy user configuration - reference: https://github.com/hydroshare/hydrodev-irods
USE_IRODS = True
IRODS_ROOT = '/tmp'
IRODS_ICOMMANDS_PATH = '/usr/bin'
IRODS_HOST = 'HS_IRODS_ICAT_IP'
IRODS_PORT = '1247'
IRODS_DEFAULT_RESOURCE = 'hydrodevResc'
IRODS_HOME_COLLECTION = '/hydrodevZone/home/hsproxy'
IRODS_CWD = '/hydrodevZone/home/hsproxy'
IRODS_ZONE = 'hydrodevZone'
IRODS_USERNAME = 'hsproxy'
IRODS_AUTH = 'proxywater1'
IRODS_GLOBAL_SESSION = True
```

Now run HydroShare as you normally would

--- 

### Other information

Subsequent runs of the `run-docker-irods.sh` script will best effort connect to the pre-existing environment that was already setup and continue from where it left off.

1. **If everything is already running:** leave all running containers as they are
2. **All containers stopped:** start the containers in order; irods-data, irods-db, and irods-icat
3. **All containers stopped and removed:** rebuild and start the containers in order; irods-data, irods-db, and irods-icat
4. **All containers stopped and removed, and all docker images removed:** rebuild the images and then rebuild and start the containers in order; irods-data, irods-db, and irods-icat

**NOTE** - The containers need to be started in the order specified by the script. If they are started out of order, or if some are running and others are not, there is no way to guarantee proper connection between them.


### Starting over with a new configuration

Because the data is persisted to the host, the directories which contain the configured data need to be removed before instantiating a new configured instance.

These files are all found in the `/srv/` directory on the host and can be removed with root privileges.

```
/srv/backup  /srv/conf  /srv/etc_irods  /srv/irods  /srv/log  /srv/pgsql /srv/tomcat /srv/java  /srv/.secret
```
**Example**

Remove all files and directories from the `/srv/` direcotry on the host

```
cd /srv
sudo rm -rf *
sudo rm -rf .secret
```
Additionally, the `irods-config.yaml` and `rodsuser-config.yaml` files are built as part of the `appstack-data` image when the script is first run. If you change your configuration settings you should also remove the `appstack-data` image prior to executing your next run of the `run-docker-irods.sh` script so that it can build in your new settings.

**Example**

Remove the `appstack-data` docker images from teh host

```
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
appstack-data       latest              fd5bcd12d002        2 hours ago         263.9 MB
...

$ docker rmi fd5bcd12d002
```

---

### Configuration Files

The configuration files are set with default attributes that will build in accordance with the standard hydrodev environment. You are welcome to adapt these settings for whatever makes the most sense in your local environment. **Note** that each config file has an intentionally blank line at the end of it.

Defaults for each file:

**irods-config.yaml**

```
SERVICE_ACCT_USERNAME: irods
SERVICE_ACCT_GROUP: irods
IRODS_ZONE: hydrodevZone
IRODS_PORT: 1247
RANGE_BEGIN: 20000
RANGE_END: 20199
VAULT_DIRECTORY: /var/lib/irods/iRODS/Vault
ZONE_KEY: TEMPORARY_zone_key
NEGOTIATION_KEY: TEMPORARY_32byte_negotiation_key
CONTROL_PLANE_PORT: 1248
CONTROL_PLANE_KEY: TEMPORARY__32byte_ctrl_plane_key
SCHEMA_VALIDATION_BASE_URI: https://schemas.irods.org/configuration
ADMINISTRATOR_USERNAME: rods
ADMINISTRATOR_PASSWORD: rods
HOSTNAME_OR_IP: irods-db
DATABASE_PORT: 5432
DATABASE_NAME: ICAT
DATABASE_USER: irods
DATABASE_PASSWORD: irods

```

**rodsuser-config.yaml**

```
RODSUSER_IRODS_RESOURCE: hydrodevResc
RODSUSER_IRODS_ZONE: hydrodevZone
RODSUSER_IRODS_USERNAME: hsproxy
RODSUSER_IRODS_AUTH: proxywater1

```

**idrop-config.yaml**

```
IDROP_CONFIG_PRESET_HOST: irods-icat
IDROP_CONFIG_PRESET_PORT: 1247
IDROP_CONFIG_PRESET_ZONE: hydrodevZone
IDROP_CONFIG_PRESET_RESOURCE: hydrodevResc

```
