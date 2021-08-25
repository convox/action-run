#!/bin/sh
if [ -n "$INPUT_RELEASE" ]
then
 export RELEASE=$INPUT_RELEASE
fi

export CONVOX_RACK=$INPUT_RACK
if [ -n "$RELEASE" ]
then
  echo "Running command on the application for the release $RELEASE"
  convox run $INPUT_SERVICE "$INPUT_COMMAND" --release $RELEASE --app $INPUT_APP --rack $INPUT_RACK
else
  echo "Running command on the application."
  convox run $INPUT_SERVICE "$INPUT_COMMAND" --app $INPUT_APP --rack $INPUT_RACK
fi