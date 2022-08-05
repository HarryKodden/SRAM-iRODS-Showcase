# SRAM-iRODS-Showcase

Showcase of iRODS with token authentication via SRAM

## Introduction

This repository contains a demo environment to show how iRODS can be connected as a Service to SRAM.
The users allowed to make use of this iRODS instance are controlled by the SRAM Colloboration.

## Preparation in SRAM

A Service must be declared in SRAM. This service has a shortname, for example 'myirodsshowcase'

Next a collabortion can be created and connect the service to that colloaboration.
Invite members to that colloboration. (For all detailed steps how SRAM works, please refer to: https://wiki.surfnet.nl/display/SRAM/How-to+guides)

The members invited to the collaboration can create a 'Service Token' which is similar to an "application specific password". This token they will need to authenticate later to iRODS as their password.

## Setup

In order to setup the full software stack to run this showcase service, you have to have installed some basic components on your platform first, the minimal shopping list required is:

- docker
- docker-compose
- make

When these components are installed and verified to function, we can continue building the stack.

### Step 1. Create iRODS software

We need to have the iRODS software, in this showcase the latest code is taken from the iRODS development repository https://github.com/irods/irods_development_environment

We need to have:

- iRODS 'runner' docker images.
- iRODS software packages.

To facilitate these steps, a separate repository is available as submodule (https://github.com/HarryKodden/iRODS-Development-Bootstrapper.git)

Update the submodule
```
git submodule update --init
```

```bash
cd iRODS-Development-Bootstrapper
export DISTRIBUTION=ubuntu20
make runners
make builds
cd ..
```

These steps will take an awfull amount of time, best to start them off, see that it is running fine and go to bed, continue the work the next morning...

Once the build process has completed the following will be created:

- docker image called "**irods-runner-ubuntu20**"
- directory called "**builds/ubuntu20/**" with 3 subdirectories:

  - client
  - server
  - packages

For this demonstration we only need the 'packages' contents.

**Note:** The builded packages for **ubuntu20** are included in this repository as well, they are added in **/build/packages**

If you have build the packages yourself, replace the packages in the ~/build/packages with your builded packages

This step is now complete !

### Step 2. Create your environment

You will need to configure your environment variables. In particular we need configuration for:

- **db.env**: database configuration
- **sram.env**: SRAM configuration
- **ldap.env**: SRAM LDAP configuration
- **irods.env**: iRODS configuration

Samples for these configuration components are provided in the **env** folder.
Just copy each sample file to a file without the **.sample** suffix. Adjust the copied file to satisy your needs.

```bash
for i in db irods ldap sram
do
  cp env/$i.env.sample env/$i.env
done
```

### db.env

```env
IRODS_DB_NAME=ICAT
IRODS_DB_PORT=5432
IRODS_DB_USER=irods_dba
IRODS_DB_PASS=password
```

For evaluation purposes, you can run with these settings. For production use, at least adjust the **IRODS_DB_PASS** to different value.

### sram.env

```env
SRAM_FLOW=TOKEN
SRAM_URL=https://sram.surf.nl
SRAM_API=<SRAM Service API Token>

SRAM_OIDC_CLIENT_ID=<<< SRAM OIDC client id >>>
SRAM_OIDC_CLIENT_SECRET=<<< SRAM OIDC client secret >>>
SRAM_OIDC_REDIRECT_URI=<<< SRAM OIDC redirect uri >>>
```


Choose `SRAM_FLOW=TOKEN` or `SRAM_FLOW=OIDC` to switch between token-based and the OIDC flow.
Here you need to add the SRAM Service API token that the Service Administrator can generate in SRAM.

### ldap.env

```env
LDAP_HOST=ldaps://ldap.sram.surf.nl
LDAP_BASE_DN=dc=flat,dc=<SRAM shortname of your connected service>,dc=services,dc=sram,dc=surf,dc=nl
LDAP_BIND_DN=cn=admin,dc=<SRAM shortname of your connected service>,dc=services,dc=sram,dc=surf,dc=nl
LDAP_ADMIN_PASSWORD=<REDACTED>
LDAP_MODE=IP_V4_ONLY
```

Here you need to collect 2 variables:

- Service shortname of your Service in SRAM
- LDAP password of the LDAP Subtree that is prepared for your Service, The Service Administrator can request for that LDAP password in SRAM.

### irods.env

```env
IRODS_SERVICE_PORT=1247
IRODS_CONTROL_PORT=1248
IRODS_RANGE_FROM=20000
IRODS_RANGE_TILL=20199
IRODS_ZONE=tempZone
IRODS_USER=irods
IRODS_PASS=password
IRODS_TRANSPORT_FROM=20000
IRODS_TRANSPORT_TILL=20199
IRODS_SERVICE_NAME=rods
IRODS_SERVICE_GROUP=shadow
```

For evaluation purposes, you can run with these settings. For production use, at least adjust the **IRODS_PASS** to different value.
The remaining values are fairly standard, but you can deviate from these if you wish.

### Step 3. Deploy software stack

This step is pretty simple. Off course much can go wrong so please look carefull to the output during deployment to see that everything looks good.

```bash
docker-compose build
docker-compose up -d
```

### Step 4: Verify proper working...

When all is configured properly, you should now be able to start a session in the **icommands** container. You can do that via 2 possible methods:

1. **docker exec -ti icommands bash**
   This is just stepping into the running container, you will have **root** privileges via this method, you can now 'become' any other user, for example: **su - \<SRAM Userid\>**

2. **ssh -P 2222 \<SRAM Userid\>@localhost** or
   **ssh -P 2222 \<SRAM Userid\>@\<FQDN or IP Address\>**
   This is the preferred method.

You may ask yourself: "<i>How is your SRAM User provisioned in this container ?</i>"

The answer is: every minute a cronjob is contacting the SRAM LDAP and mirrors each SRAM collaboration member as a valid user in this container as well as a valid iRODS user in the iRODS Catalogue.

Next, try out your first **irods** command, for example:

```bash
$ ils<enter>
```

When everythig is setup properly the system sould respond with:

```bash
$ ils
Enter your current PAM password:
```

Now copy/paste the SRAM token that you have registered as your Service Token in SRAM. If you have pasted an incorrect token, the system will respond:

```bash
$ ils
Enter your current PAM password:
Error occurred while authenticating user [testuser] [PAM_AUTH_PASSWORD_FAILED: failed to perform request

] [ec=-993000] failed with error -993000 PAM_AUTH_PASSWORD_FAILED
```

Enter a valid token will result in:

```bash
$ ils
/tempZone/home/testuser:
```

You can now experiment with irods, for an introduction on the possible commands:

```bash
$ ihelp<enter>
```
