# Convox Run Action
This Action runs a [One-off Command](https://docs.convox.com/management/one-off-commands) using a specific release of an app on Convox. A typical use case of this action would be to run migrations or a similar pre-deploy or post-deploy command.

> **Note:** In the default attached mode this action allocates a pseudo-TTY for proper output streaming and color support in GitHub Actions runners.

## Inputs
### `rack`
**Required** The name of the [Convox Rack](https://docs.convox.com/introduction/rack) containing the app you wish to run the command against
### `app`
**Required** The name of the [app](https://docs.convox.com/deployment/creating-an-application) you wish to run the command against
### `service`
**Required** The name of the [service](https://docs.convox.com/application/services) to run the command against
### `command`
**Required** The command you wish to run. Line breaks are turned into spaces, so a multi-line value runs as a single command line.
### `release`
**Optional** The ID of the [release](https://docs.convox.com/deployment/releases) you wish to run the command against. If you have run a Build action as a previous step your command will run using the release created by that build step by default. You only need to set the release if you have not run a build step first or you wish to override the release id from the build step. If there is no release from either, the command runs against the currently promoted release.
### `wait`
**Optional** Set to `true` to run the command detached and wait for it to finish. The step exits with the command's own exit status, and a brief connection drop does not change the result. Requires a V3 rack on 3.25.5 or later. Defaults to `false`.
### `timeout`
**Optional** Seconds, from 1 to 999999999. Defaults to `3600`. In the default attached mode this is how long the command may run before it is stopped. With `wait` it is how long the step waits for the command, checked every 5 seconds, so use at least 10; when it runs out the step fails but the command keeps running on the rack. Not used with `detach`.
### `detach`
**Optional** Set to `true` to start the command and return as soon as the rack accepts it. A passing step means the command was accepted, not that it ran or succeeded. Ignored when `wait` is `true`. Defaults to `false`.
### `retain`
**Optional** Seconds to keep the finished process readable by `convox ps info`, so a later step can check its status. Requires `wait` or `detach`, and a V3 rack on 3.25.5 or later. With `wait` the process is always kept for at least 60 seconds; the rack keeps it for at most 600.

## Outputs
### `pid`
The ID of the process started with `wait` or `detach`, available as `${{ steps.<id>.outputs.pid }}`. Empty in the default attached mode.

## Modes
| Mode | Set | Command output in the step log | Step result |
|------|-----|--------------------------------|-------------|
| Attached (default) | nothing | streamed | the command's exit status; if the connection drops the step fails and the command is stopped |
| Wait | `wait: true` | not shown, only the process ID | the command's exit status, even if the connection drops |
| Detach | `detach: true` | not shown, only the process ID | passes once the rack accepts the command |

`wait` needs a V3 rack on 3.25.5 or later. On an older V3 rack, or on a V2 rack, a `wait` step fails every time, even when the command succeeds, because the rack does not report the command's exit status. It never passes when the outcome is unknown.

If a `wait` step fails because it ran out of `timeout`, or because the rack could not be reached twice in a row, the command is still running. Check `convox ps` before running it again. To put a hard limit on the command itself, wrap it, for example `timeout 1800 rake db:migrate`.

In attached mode the command is wrapped in single quotes, so a command that itself contains a single quote does not run as written. Use double quotes inside the command, or use `wait`, which passes the command unchanged.

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
  uses: convox/action-build@v2
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

To promote only after a long migration has finished, whatever happens to the connection, add `wait` to the migrate step:
```
- name: migrate
  id: migrate
  uses: convox/action-run@v1
  with:
    rack: staging
    app: myapp
    service: web
    command: 'rails db:migrate'
    release: ${{ steps.build.outputs.release }}
    wait: true
    timeout: 7200
```

## Convox CLI version
This action installs the latest Convox CLI release when its image is built, so the action's version tag does not pin the CLI. On GitHub-hosted runners that happens on every run. On a self-hosted runner with a persistent Docker daemon, the CLI stays at the version cached in that daemon until its build cache is pruned, and `wait`, `detach`, and `retain` fail with `unknown flag` if that cached CLI is older than 3.25.5.
