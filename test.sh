#!/bin/bash

ROOT="$( cd "$( dirname "$0" )" && pwd )"

if [ ! -d "$ROOT/tests/testbox" ]; then
	cd "$ROOT" && box install
fi

cd "$ROOT"

box server start serverConfigFile=server-dataapitests.json --noSaveSettings

cd tests
box testbox run --verbose outputFile=results/test-results outputFormats=json,antjunit
exitcode=$?

exit $exitcode
