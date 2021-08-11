- [Use Case](#use-case)
  * [You and your clients](#you-and-your-clients)
  * [The apps](#the-apps)
- [CI/CD implementation](#cicd-implementation)
  * [Focus on APIs](#focus-on-apis)
    + [Github actions](#github-actions)
    + [Generate the API description](#generate-the-api-description)
    + [Publish to the API Manager](#publish-to-the-api-manager)
    + [`api-spec.yaml`](#api-specyaml)
    + [`api-image.jpg`](#api-imagejpg)
    + [Mocking a service](#mocking-a-service)
    + [Overriding defaults](#overriding-defaults)
  * [Focus on Apps](#focus-on-apps)
    + [`./.github/workflows/apps.yaml`](#githubworkflowsappsyaml)
    + [`./apps/<my_app>/application-config.json`](#appsmy_appapplication-configjson)
    + [Adding or deleting an app](#adding-or-deleting-an-app)
- [Runthings locally](#runthings-locally)
  * [Installing json-merger](#installing-json-merger)
  * [Installing the APIM](#installing-the-apim)
  * [Publishing an API](#publishing-an-api)
  * [Publishing an app](#publishing-an-app)
- [I want to fork.](#i-want-to-fork)
  * [Prerequisites](#prerequisites)
  * [Setting the secrets](#setting-the-secrets)
  
# Example repository for Axway CLI - Techlab Loyalty

This repository is meant as a short example on a simple usecase to illustrate the flexibility of the Axway API Manager.

We will first introduce the usecase, and dig a bit more into how the CI/CD pipeline is rendered.

A last section is made available with instructions, should you want to fork this repository.

## Use Case

### You and your clients
You run an Axway API manager with a set of APIs linked to services you run for your clients.
These services deliver coupons to whomever is calling them.
Your clients include Nike, Puma, Décathlon and Amazon.

This Gateway is more directly targeted at the <u>**partners**</u> of your clients, which happen to be 
two loyalty pure-player startups:

### The apps

**GodFather**

A end user (a Godfather) gets coupons to distribute to their friends (Godchildren). Godfathers receive coupons for theirselves whenever sufficient coupons from godchildren have been consumed.
so in brief: The more coupons a godfather spreads, the more coupons he gets for himself.

This service seeks partnership with whoever is issuing coupons, and gets money back from the direct marketing that their userbase can deploy.

**Sportswear**

Users of this service can get access to specific discounts for sportswear items like sneakers, caps, sweaters etc.

This service wants to access to coupons for any sjop or retail that issues sportswears. It gets incomes from the brands that can lean on them for specific marketing operations.


## CI/CD implementation

This repository, being a Github one, uses Github Actions to run its ci/cd pipelines.
Note however that we make no use of any tricky or specific functionnalities of GitHub, so the whole lot is portable to other CI/CD technologies like GitlabCI, CircleCI, Jenkins, etc...

### <a href="apis"></a>Focus on APIs

All the apis in this repository have the same layout

    .
    ├── .github
    │   └── workflows
    │       └── <my_api>.yaml
    ├── apis
    │   ├── defaults.json
    │   └── <my_api>
    │       ├── Dockerfile
    │       ├── api-config-tpl.json
    │       ├── api-image.jpg
    │       ├── api-spec.yaml
    │       └── puma-new.jpg
    ├── package-lock.json
    └── package.json

#### Github actions
`./.github/workflow/<my_api>.yaml` defines the actions that will be triggered on a push to the `main` branch, whose commits affects at least one file in the `./apis/<my_api>` folder (change, addition or deletion of a file).  
The steps are:
 - [generate](#generate) an API description for `<my_api>`
 - [publish](#publish) the api to the gateway
 - (if needed) create and publish a docker image mocking the service (based on [the API specifications](#api-spec.yaml))

#### <a name="generate"></a>Generate the API description
To publish a new API or update an existing one, The API Manager takes a JSON file describing various fields and properties regarding it, like the version, name, path, description, image for the API.
This is the `api-config.json` file.  
This file is not present in this layout: as many of these fields are often similar from an API to the next, this project _generates_ it from:
  * a default file (`./apis/defaults.json`) containing the expected stucture
  * a merging file (`./apis/<my_api>/api-config.tpl.json`) containing some overrides

We call [json-merger](https://www.npmjs.com/package/json-merger) to do the actual merging.  
Simply put, `json-merger` will take the `defaults.json` file and substitute some fields with values in the `api-config-tpl.json` file to obtain the final file.

See [`defaults.json`](#defaults) to learn how to override values.

#### <a name="publish"></a>Publish to the API Manager
Axway provides a fully fedged CLI to create/update apis and apps to an Axway API Manager.  
This is what we use in the Github action to communicate with the API Manager.  
To do so effectively, we need some informations that are rendered in this repository as secrets:

| **Name**    | **Example**              | **Description**                                     |
|-------------|--------------------------|-----------------------------------------------------|
| `APIM_HOST` | `api-env.demo.axway.com` | The FQDN of where your Axway API Manager is located |
| `APIM_PORT` | `8075`                   | The port of your Axway API Manager                  |
| `APIM_USER` | `apiadmin`               | The username we will use to act on the APIM (must have admin powers) |
| `APIM_PASS` | `changeme`               | The corresponding password                          |

#### <a name="api-spec.yaml"></a>`api-spec.yaml`
The OpenAPI / Swagger definition of the API. This can be a YAML in [OAS 3.x](https://swagger.io/specification/) or [Swagger 2.x](https://swagger.io/specification/v2/) formats.

This file is referenced in the [`defaults.json`](#defaults) file.

#### <a name="api-image.jpg"></a>`api-image.jpg`
The API logo. This image is ideally a squared 500x500 image.  
Avoid :
  - < 200x200
  - &gt; 1000x1000
  - &gt; 1MB

This file is referenced in the [`defaults.json`](#defaults) file.

#### <a name="mock"></a>Mocking a service
Each api has a `Dockerfile` creating a dynamic mock of the api with [prism](https://github.com/stoplightio/prism).
This mock is pushed to the Docker Hub, using the following repository secrets:
| **Name**             | **Example**                           | **Description** |
|----------------------|---------------------------------------|----|
| `DOCKERHUB_USERNAME` | `goodwillhunting`                     | The name of the DockerHub account |
| `DOCKERHUB_TOKEN`    | `bbf5ee09-e49c-41b7-95f7-e6a22239ec6c`| A [PAT](https://docs.docker.com/docker-hub/access-tokens/) for this account |

The mock will be published in `<DOCKERHUB_USERNAME>/mock-<api_name>:main`, examples `goodwillhunting/mock-mclaurin:main`.

You can run this mock with:

    docker run -it --rm -p 4010:4010 goodwillhunting/mock-mclaurin:main

Prism will tell you what pathes it is listening on, and gets you useful information on each call.  
You can test that by issuing:

    curl http://localhost:4010/<somepath>

Change `<somepath>` with one given by prism on startup.

#### <a name="defaults"></a>Overriding defaults
The file `defaults.json` has the expected structure for the APIM cli to work properly.
Some fields are left blank, and are hence expected to be filled by each API:
```yaml
{
  # The name of the API, this is the main human reference for your API in the APIM 
  "name": "",
  # The first components of the path for your API. This must be unique in the APIM
  "path": "",
  # Whether the API is published (i.e. accessible) or unpublished (i.e. referenced but not accessible) 
  "state": "published",
  # can be any string, semver recommended 
  "version": "",
  # the name of the organization in which the API will be created.
  #  /!\ the org will be created if it does not exist 
  "organization": "API Development",
  # The file to read (relative to <my_api> folder) to get the Swagger/OAS specifications of your API
  "apiDefinition": "api-spec.yaml",
  # Some words about what your API can do
  "summary": "",
  # The URL at which the backend service can be joined.
  "backendBasepath": "",
  # The file to read (relative to <my_api> folder) to get a logo for your API 
  "image": "api-image.jpg",
  "securityProfiles": [
     # defines a API Key security protection for the frontend 
  ],
  "tags": {
    # defines a set of tags for the API
  },
  "clientOrganizations": [
    # Which organizations can access your API freely
  ]
}
```
The `api-config-tpl.json` file can override any of these values:
```yaml
{
  "$merge": {
    # Tells json-merger to merge "source" with the "with" object:
    #   - ../default.json (see above) is read
    #   - the "with" object is then overlayed:
    #       1. 'simple' or 'complex' unexistent keys are created
    #       2. 'simple' existent types are overrided
    #       3. 'complex' keys (arrays, objects) are merged recursively (back to 1.)
    "source": {
      "$import": "../defaults.json"
    },
    "with": {
      "name": "Nice API Name",
      "summary": "My new API will eat the world!",
      "path": "/amazing",
      "version": "1.0",
      "backendBasepath": "https://amazing.world/"
    }
  }
}
```

If you want for instance to specify `new-shiny-image.png` as your new API logo, you can:
* place this image in the API folder (`./apis/`)
* edit the `api-config-tpl.json` to override the `"image"` field:
```json
{
  "$merge": {
    "source": {
      "$import": "../defaults.json"
    },
    "with": {
      "name": "Nice API Name",
      "summary": "My new API will eat the world!",
      "path": "/amazing",
      "version": "1.0",
      "backendBasepath": "https://amazing.world/",
      "image": "new-shiny-image.png"
    }
  }
}
```

### Focus on Apps

    .
    ├── .github
    │   └── workflows
    │       └── apps.yaml
    └── apps
        └── <my_app>
            ├── app-image.jpg
            └── application-config.json

In contrast with [apis](#apis), publishing applications is way easier. Two files are worth mentioning:

#### `./.github/workflows/apps.yaml`
This file will publish **all** the applications when:
* a push is done on the main branch
* a commit of said push makes **anything** in the `./apps/` (creates a new file, deletes a file, moves to/from it, updates an existing, looks at it, even sideways)

Please note that the apps to publish are listed explicitly in this file. To change that list, see [Ading or deleting an app](#list-apps) below.

#### `./apps/<my_app>/application-config.json`
This file defines what the application will look like in the API Manager:
```yaml
{
  # A nice name for your app. This is what your app is called in the APIM UI
  "name": "Nice App",
  # The organization in which to create the app 
  "organization": "API Development",
  # Some words about your app 
  "description": "The best app ever",
  # To make sure that the app is usable (i.e. approved and enabled) 
  "state": "approved",
  "enabled": true,
  "credentials": [
    # A list of credentials for the application
  ],
  "apis": [
    # A list of apis this app can access
  ],
  "appQuota": {
    # The limits APIM will enforce regarding this app's usage
  }
}
```

#### <a name="list-apps"></a>Adding or deleting an app

To create a `my-new-app`, you can create a new app folder `./apps/my-new-app`, by copying an existing one and adapting the `application-config.json` file accordingly for instance.
You also have to change the `./.github/workflows/apps.yaml` by adding `my-new-app` in the `jobs.Apps-Deployment.strategy.matrix.app` array:
```yaml
name: Deploy all apps
on:
  ## eluded
jobs:
  Apps-Deployment:
    if: "!contains(github.event.head_commit.message, '[SKIP-CI]')" 
    runs-on: ubuntu-latest
    strategy:
      matrix:
        app:
          - old-app
          - my-new-app ## <- here
    steps:
      ## eluded, nothing to change here
```
Commit, push et voilà.

To remove an app, remove its name from the `./.github/workflows/apps.yaml`, remove the folder, commit push, and remove the app from the APIM manually (there is currently no way of doing it via the cli)

## Runthings locally

This is for you to poke around and see what is going on in the CI/CD pipeline with your own eyes.

### Installing json-merger
`json-merger` is used to create the API configuration files out of some defaults and some overrides.  
It is a npm module so assuming `node`and `npm`are installed, you can go at the root of your project and issue:
```bash
$ npm i -y
```
```
added 29 packages, and audited 30 packages in 960ms

found 0 vulnerabilities
```


### Installing the APIM

This will create the final file, so that you can have a look at it. Note that you are never required to do so yourself.

You can install it by following the instructions [here](https://github.com/Axway-API-Management-Plus/apim-cli)

### Publishing an API

Assuming that you installed `json-merger` and `apim`:
```bash
$ cd apis/my-api
$ npx json-merger api-config-tpl.json > api-config.json
$ apim -h apim.url.here.com -port 8075 \
     -u apiadmin -p 'ChangeThisForYourPassword' \
     api import -c api-config.json
```
```

----------------------------------------------------------------------------------------
API-Manager CLI: 1.3.7
                                                                        
To report issues or get help, please visit: 
https://github.com/Axway-API-Management-Plus/apim-cli
----------------------------------------------------------------------------------------
Module: API - I M P O R T (1.3.7)
----------------------------------------------------------------------------------------
0      INFO     APIManagerAdapter| Successfully connected to (...)
327    INFO  IImportConfigAdapter| Reading API-Definition (Sw(...)
384    INFO      APISpecification| Used the backendBasepath: (...)
411    INFO  IImportConfigAdapter| Loading image from: '/User(...)
3639   INFO  APIManagerAPIAdapter| Found existing API on path(...)
4415   WARN          APIImportApp| No changes detected betwee(...)
No changes detected. Existing with RC: 0
```
The output is truncated to make it more readable, and in this particular run, nothing was done since the published API was the same as the one I was sending, and the `apim` command is clever enough to realize that.

### Publishing an app
Assuming that you installed `apim`:
```bash
$ cd apis/my-api
$ apim -h apim.url.here.com -port 8075 \
     -u apiadmin -p 'ChangeThisForYourPassword' \
     app import -c application-config.json
```
```

----------------------------------------------------------------------------------------
API-Manager CLI: 1.3.7
                                                                        
To report issues or get help, please visit: 
https://github.com/Axway-API-Management-Plus/apim-cli
----------------------------------------------------------------------------------------
Module: Application - I M P O R T (1.3.7)
----------------------------------------------------------------------------------------
0      INFO     APIManagerAdapter| Successfully connected to (...)
3701   INFO  ApplicationImportApp| Successfully replicated ap(...)

```
The output is truncated to make it more readable, but the output is sufficiently explicit.

## I want to fork.

Please do.

This section describe what you need to change on your fork to make it work properly

### Prerequisites

* From the API Manager:  
  * You are expected to have a running Axway API Manager, so that the APIM CLI can
interact with it and publish. Setting an Axway API Manager is beyond the scope of this documentation. 
  * The username and password of an api admin is also required.
* From Docker Hub, you need a username and a [PAT](https://docs.docker.com/docker-hub/access-tokens/)

### Setting the secrets

| **Name**             | **Example**                           | **Description** |
|----------------------|---------------------------------------|----|
| `DOCKERHUB_USERNAME` | `goodwillhunting`                     | The name of the DockerHub account |
| `DOCKERHUB_TOKEN`    | `bbf5ee09-e49c-41b7-95f7-e6a22239ec6c`| A [PAT](https://docs.docker.com/docker-hub/access-tokens/) for this account |
| `APIM_HOST`          | `api-env.demo.axway.com`              | The FQDN of where your Axway API Manager is located |
| `APIM_PORT`          | `8075`                                | The port of your Axway API Manager |
| `APIM_USER`          | `apiadmin`                            | The username we will use to act on the APIM (must have api admin powers) |
| `APIM_PASS`          | `changeme`                            | The corresponding password |

Happy forking!
