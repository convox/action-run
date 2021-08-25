# Convox Run Action
This Action runs a [One-off Command](https://docs.convox.com/management/one-off-commands) using a specific release of an app on Convox. A typical use case of this action would be to run migrations or a similar pre-deploy or post-deploy command.

## Inputs
### `rack`
**Required** The name of the [Convox Rack](https://docs.convox.com/introduction/rack) containing the app you wish to run the command against
### `app`
**Required** The name of the [app](https://docs.convox.com/deployment/creating-an-application) you wish to run the command against
### `service`
**Required** The name of the [service](https://docs.convox.com/application/services) to run the command against
### `command`
**Required** The command you wish to run
### `release`
**Optional** The ID of the [release](https://docs.convox.com/deployment/releases) you wish to run the command against. If you have run a Build action as a previous step your command will run using the release created by that build step by default. You only need to set the release if you have not run a build step first or you wish to override the release id from the build step
## Example usage
```
steps:
- name: login
  id: login
  uses: convox/action-login@v2
  with:
    password: ${{ secrets.CONVOX_DEPLOY_KEY }}
- name: build
  id: build
  uses: convox/action-build@v1
  with:
    rack: staging
    app: myapp
- name: migrate
  id: migrate
  uses: convox/action-run@v1
  with:
    rack: staging
    app: myapp
    service: web
    command: 'rails db:migrate'
    release: ${{ steps.build.outputs.release }}
- name: promote
  id: promote
  uses: convox/action-promote@v1
  with:
    rack: staging
    app: myapp
    release: ${{ steps.build.outputs.release }}
```
