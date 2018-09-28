#!/bin/bash

if [ ! -d "`dirname $0`/tests/testbox" ]; then
  box install
fi

cd `dirname $0`/tests
CWD="`pwd`"

testresults=$( box "$CWD/runTests.cfm" )
echo $testresults

exitcode=$(<.exitcode)
rm -f .exitcode

if [ $exitcode == 1 ]; then
  box slack send message color="danger" message="${testresults}"
fi

exit $exitcode
