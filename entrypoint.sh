#!/bin/sh
set -e

if [ -z "${INPUT_RACK:-}" ]; then
  echo "::error::Required input 'rack' is missing"
  exit 1
fi
if [ -z "${INPUT_APP:-}" ]; then
  echo "::error::Required input 'app' is missing"
  exit 1
fi
if [ -z "${INPUT_SERVICE:-}" ]; then
  echo "::error::Required input 'service' is missing"
  exit 1
fi
if [ -z "${INPUT_COMMAND:-}" ]; then
  echo "::error::Required input 'command' is missing"
  exit 1
fi

TIMEOUT="${INPUT_TIMEOUT:-3600}"
WAIT="${INPUT_WAIT:-false}"
DETACH="${INPUT_DETACH:-false}"
RETAIN="${INPUT_RETAIN:-}"

seconds() {
  case "$1" in
    ''|*[!0-9]*|0*) return 1 ;;
  esac
  [ "${#1}" -le 9 ]
}

if ! seconds "$TIMEOUT"; then
  echo "::error::Input 'timeout' must be a whole number of seconds from 1 to 999999999"
  exit 1
fi
case "$WAIT" in
  true|false) ;;
  *) echo "::error::Input 'wait' must be true or false"; exit 1 ;;
esac
case "$DETACH" in
  true|false) ;;
  *) echo "::error::Input 'detach' must be true or false"; exit 1 ;;
esac
if [ -n "$RETAIN" ]; then
  if ! seconds "$RETAIN"; then
    echo "::error::Input 'retain' must be a whole number of seconds from 1 to 999999999"
    exit 1
  fi
  if [ "$WAIT" != "true" ] && [ "$DETACH" != "true" ]; then
    echo "::error::Input 'retain' requires 'wait' or 'detach'"
    exit 1
  fi
fi

if [ -n "$INPUT_RELEASE" ]
then
 export RELEASE="$INPUT_RELEASE"
fi

export CONVOX_RACK="$INPUT_RACK"

CONVOX_ARGS="--app $INPUT_APP --rack $INPUT_RACK"
# Note: CONVOX_ARGS is expanded inside a script -c string below where it is
# re-parsed by /bin/sh, so inner quoting is intentionally omitted here.
if [ -n "$RELEASE" ]
then
  echo "Running command on the application for the release $RELEASE"
  CONVOX_ARGS="--release $RELEASE $CONVOX_ARGS"
else
  echo "Running command on the application."
fi

if [ "$WAIT" = "true" ] || [ "$DETACH" = "true" ]; then
  set -- --detach --id --app "$INPUT_APP" --rack "$INPUT_RACK"
  if [ -n "$RELEASE" ]; then
    set -- "$@" --release "$RELEASE"
  fi
  if [ "$WAIT" = "true" ]; then
    set -- "$@" --wait --timeout "$TIMEOUT"
  fi
  if [ -n "$RETAIN" ]; then
    set -- "$@" --retain "$RETAIN"
  fi
  command=$(printf '%s' "$INPUT_COMMAND" | tr '\r\n' '  ')

  set +e
  pid=$(convox run "$@" -- "$INPUT_SERVICE" "$command")
  exit_code=$?
  set -e

  if [ -n "$pid" ]; then
    echo "pid=$pid" >> "$GITHUB_OUTPUT"
  fi
  if [ "$WAIT" = "true" ]; then
    echo "Command completed with exit code: $exit_code"
  fi
  exit $exit_code
fi

# Use 'script' to allocate a pseudo-TTY. GitHub Actions runners provide a
# non-interactive terminal, which causes convox run to disable TTY mode.
# Without TTY mode the WebSocket/SPDY connection to the Kubernetes pod hangs
# or fails to return output.
#
# Flags: -q (quiet), -e (return child exit code), -c (run command)
# /dev/null discards the typescript recording file.
set +e
script -qec "convox run $INPUT_SERVICE '$INPUT_COMMAND' --timeout $TIMEOUT $CONVOX_ARGS" /dev/null
exit_code=$?
set -e

echo "Command completed with exit code: $exit_code"
exit $exit_code
