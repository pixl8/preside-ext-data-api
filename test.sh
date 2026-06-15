#!/bin/bash

ROOT="$( cd "$( dirname "$0" )" && pwd )"

if [ ! -d "$ROOT/tests/testbox" ]; then
	cd "$ROOT" && box install
fi

cd "$ROOT/tests"

box server start serverConfigFile=server.json --noSaveSettings

mkdir -p results
box testbox run --verbose outputFile=results/test-results outputFormats=json,antjunit
exitcode=$?

exit $exitcode
