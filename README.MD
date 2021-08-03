# Example repository for Axway CLI

## Purpose
The main aim of this repository is to illustrate how the APIM CLI works
in a CI/CD workload.

Broadly speaking, we have one job per business, that will :
* generate the expected configuration file [`api-config.json`](#api-config.json) for each api in it
* invoke the [apim-cli](#https://github.com/Axway-API-Management-Plus/apim-cli) on each api to import it in your API Manager.

You need to set some Github secrets on your repository for this to work. See [setup](#setup) for further instructions on how to do this.

## Setup

First, fork this repository.

### Prerequisites
You are expected to have a running Axway API Manager, so that the APIM CLI can
interact with it and publish. Setting an Axway API Manager is beyond the scope of this documentation. 

Please take good note on the following information, as you will need it on the [setup](#setup) phase:
* The domain name and port of the Axway API Manager: This _must_ be an URL accessible on the Internet for this repository to work.
* The username and password of a user on the API. It can be the `apiadmin`, but depending on what you are trying to achieve, it can be a lesser privileged user.

### Setting the secrets
Then, create the following (GitHub secrets)[https://docs.github.com/en/actions/reference/encrypted-secrets] in your own fork:

| **Name**    | **Example**              | **Description**                               |
|-------------|--------------------------|-----------------------------------------------|
| `APIM_HOST` | `api-env.demo.axway.com` | The FQDN of where your Axway API Manager is located |
| `APIM_PORT` | `8075`                   | The port of your Axway API Manager                  |
| `APIM_USER` | `apiadmin`               |                                               |
| `APIM_PASS` | `changeme`               |                                               |

#### Your API Manager is accessible from the Internet
You are done. The Github acitons will be run by Github Runners, and they will be able to connect to your Axway API Manager correctly.

#### Your API Manager is _not_ accessible from the internet
The easier way to get going is to [host your own Github Actions Runner](https://docs.github.com/en/actions/hosting-your-own-runners).
This is well beyond the scope of this documentation.

Just note that your self-hosted runner :
* must be able to connect to the API Manager.
* must be able to access Github
* need not be accessible from the internet

The values for `APIM_HOST` and `APIM_PORT` should make sense _to your runner_. For example, if the runner and the API Manager are on the same machine, `APIM_HOST` can (and probably should) be valued to `localhost`.

In this setting, be aware that your runner becomes an important part of your CI/CD pipeline and should be monitored accordingly.

### Testing the setup
The settings are now finished.

To test your setup, execute the `test-ci.sh` at the root of the project.
This will basically create a test branch, a test workflow and push the whole thing to your repository, wait a bitto let you check that the workflow is run correctly, then delete this test branch.

The expected outcome is that a workflow listing the apis known to the API Manager is triggered.
This would confirm that the secrets and the connectivity from the runners and the API Manager are in place.

## Usage

Commit and push as usual.  
Each push will trigger a publication of a given business if:
* you are on branch `demo`
* one file in the business has changed in any way.
* the last commit of the push does not contain the token `[SKIP-CI]` in its comment.

Have a look at [a workflow example](#workflow) to understand how it works under the hood.

## Layout of the project

This project is layed out this way

    .
    ├── <boilerplate>
    ├── package.json, package-lock.json
    ├── <business>
    │   ├── <api>
    │   │   ├── api-config-tpl.json
    │   │   ├── api-image.jpg
    │   │   └── api-spec.yaml
    │   └── defaults.json
    └── .github
        └── workflows
            └── publish-<business>.yml

For instance, there are 4 businesses: `couponing`, `health_authority`, `insurtech`, `iot`.  
In `couponing`, you will find 4 apis: `amazon`, `decathlon`, `nike`, `puma`

### `<boilerplate>`

* `README.MD`, `LICENCE.MD`,`.gitignore` which are usual
* `.gitignore` which excludes [`api-config.json`](#api-config.json) (more on that later) 

### `package.json`, `package-lock.json`, `node_modules`

We need `json-merger` to generate the [`api-config.json`](#api-config.json) file.
Since this is a nodejs piece, having these two files is the most simple way to make it readily available for us on the CI/CD pipeline.
It is possible that you never see the `node_modules` directory. Don't worry, its a technicality and can be safely ignored.

### <a name="business"></a>`<business>`
A line of business, with a folder per API that must be exposed for this business.

### <a name="api"></a>`<api>`
One single API that we want to deal here.
In this folder, we can find a set of important files, see below.

### `api-config-tpl.json`, `api-config.json`, `defaults.json`
<a name="api-config-tpl.json"></a><a name="api-config.json"></a><a name="defaults.json"></a>
`api-config-tpl.json` is a template that is merged with `defaults.json` to produce  `api-config.json`, which is the main configuration to the apim-cli.
Example:

`defaults.json`

    {
      "name": "",
      "path": "",
      "state": "published",
      "version": "",
      "organization": "API Development",
      "apiDefinition": "api-spec.yaml",
      "backendBasepath": "http://ptx136.demo.axway.com:8081/",
      "image": "api-image.jpg",
      "securityProfiles": [
        {
          "name": "_default",
          "isDefault": true,
          "devices": [
            {
              "name": "API Key",
              "type": "apiKey",
              "order": 1,
              "properties": {
                "apiKeyFieldName": "KeyId",
                "takeFrom": "HEADER",
                "removeCredentialsOnSuccess": "true"
              }
            }
          ]
        }
      ],
      "clientOrganizations": [
        "API Development"
      ]
    }

`api-config-tpl.json`

    {
      "$merge": {
        "source": {
          "$import": "../defaults.json"
        },
        "with": {
          "name": "Good Food Good Life",
          "summary": "",
          "path": "/gfgl",
          "version": "1.0"
        }
      }
    }

`api-config.json`

    {
      "name": "Good Food Good Life",    # <- FROM api-config-tpl.json
      "path": "/gfgl",                  # <- FROM api-config-tpl.json
      "state": "published",     
      "version": "1.0",                 # <- FROM api-config-tpl.json
      "summary": ""                     # <- FROM api-config-tpl.json
      "organization": "API Development",
      "apiDefinition": "api-spec.yaml",
      "backendBasepath": "http://ptx136.demo.axway.com:8081/",
      "image": "api-image.jpg",
      "securityProfiles": [
        {
          "name": "_default",
          "isDefault": true,
          "devices": [
            {
              "name": "API Key",
              "type": "apiKey",
              "order": 1,
              "properties": {
                "apiKeyFieldName": "KeyId",
                "takeFrom": "HEADER",
                "removeCredentialsOnSuccess": "true"
              }
            }
          ]
        }
      ],
      "clientOrganizations": [
        "API Development"
      ]
    }

The rest of fileds maps more or less one to one with those of the screens in the API Manager to create a ew frontend/backend pair.

### <a name="api-image.jpg"></a>`api-image.jpg`
Referenced by [`api-image.json`](#api-image.json): The image that will serve as an avatar for the API.

### <a name="api-spec.yaml"></a>`api-spec.yaml`
Referenced by [`api-config.json`](#api-config.json): The OpenAPI/Swagger definition for the API.

### .github / workflows
Where Github workflows live. A workflow is triggered in response of a whole lot of events in the life of a repository/project.
Each file here will be evaluated on every new event.

### <a name="workflow"></a>`publish-<business>.yml`
Lets have a look at an example; all are alike anyways.

    name: Deploy all Couponning APIs

    on:
      push:
        branches:
          - demo
        paths: couponing/**
    jobs:
      Couponing-API-Deployment:
        if: "!contains(github.event.head_commit.message, '[SKIP-CI]')" 
        runs-on: ubuntu-latest
        strategy:
          matrix:
            api:
              - amazon
              - decathlon
              - nike
              - puma
        steps:
          - name: Checkout the git repository
            uses: actions/checkout@v2
          - name: Generate api-config.json
            uses: actions/setup-node@v2
            with:
              node-version: '16'
          - run: npm i -y
          - run: npx json-merger couponing/${{ matrix.api }}/api-config-tpl.json |jq . >   couponing/${{ matrix.api }}/api-config.json
          - name: Publish to APIM
            uses: Axway/presales-apim-cli-action@v0
            env:
              APIM_USER: ${{ secrets.APIM_USER }}
              APIM_PASS: ${{ secrets.APIM_PASS }}
              APIM_HOST: ${{ secrets.APIM_HOST }}
              APIM_PORT: ${{ secrets.APIM_PORT }}
            with:
              command: api import -c couponing/${{ matrix.api }}/api-config.json

Breaking this down:

   name: Deploy all Couponning APIs

    on:
      push:
        branches:
          - demo
        paths: couponing/**

Give a name to the workflow, and mark interrest on push events that registers a modification on business `couponing`.

    jobs:
      Couponing-API-Deployment:
        if: "!contains(github.event.head_commit.message, '[SKIP-CI]')" 
        runs-on: ubuntu-latest
        strategy:
          matrix:
            api:
              - amazon
              - decathlon
              - nike
              - puma

Configuring the jobs we are running. Here, we will run every steps for each api un parallel (matrix strategy does that). Steps will run in the latest ubuntu OS, and only if the last commit of the push we are dealing with does not have `[SKIP-CI]` in its commit message.

    steps:
      - name: Checkout the git repository
        uses: actions/checkout@v2
      - name: Generate api-config.json
        uses: actions/setup-node@v2
        with:
          node-version: '16'

First step is about checking out our repository and getting NodeJS v16 in scope.

      - run: npm i -y
      - run: npx json-merger couponing/${{ matrix.api }}/api-config-tpl.json |jq . >   couponing/${{ matrix.api }}/api-config.json

Then install the needed NodeJS packages (`npm i -y`) and run `json-merger` to generate the [`api-config.json`](#api-config.json).

      - name: Publish to APIM
        uses: Axway/presales-apim-cli-action@v0
        env:
          APIM_USER: ${{ secrets.APIM_USER }}
          APIM_PASS: ${{ secrets.APIM_PASS }}
          APIM_HOST: ${{ secrets.APIM_HOST }}
          APIM_PORT: ${{ secrets.APIM_PORT }}
        with:
          command: api import -c couponing/${{ matrix.api }}/api-config.json

Lastly, we run the `api import` command from [`apim-cli`](https://github.com/Axway-API-Management-Plus/apim-cli/wiki#supported-commands)