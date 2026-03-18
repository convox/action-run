#!/bin/sh
if [ -n "$INPUT_RELEASE" ]
then
 export RELEASE=$INPUT_RELEASE
fi

export CONVOX_RACK=$INPUT_RACK

CONVOX_ARGS="--app $INPUT_APP --rack $INPUT_RACK"
if [ -n "$RELEASE" ]
then
  echo "Running command on the application for the release $RELEASE"
  CONVOX_ARGS="--release $RELEASE $CONVOX_ARGS"
else
  echo "Running command on the application."
fi

# Use 'script' to allocate a pseudo-TTY. GitHub Actions runners provide a
# non-interactive terminal, which causes convox run to disable TTY mode.
# Without TTY mode the WebSocket/SPDY connection to the Kubernetes pod hangs
# or fails to return output.
#
# Flags: -q (quiet), -e (return child exit code), -c (run command)
# /dev/null discards the typescript recording file.
set +e
script -qec "convox run $INPUT_SERVICE '$INPUT_COMMAND' $CONVOX_ARGS" /dev/null
exit_code=$?
set -e

echo "Command completed with exit code: $exit_code"
exit $exit_code