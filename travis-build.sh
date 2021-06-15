#!/bin/bash

set -eou pipefail

# Travis aborts the build if it doesn't get output for 10 minutes.
keepAlive() {
  while [ -f $1 ]
  do
    sleep 10
    echo .
  done
}

buildiOSApp() {
  echo Building the iOS test app
  cd TestApp
  pod install --repo-update
  CODE=0
  xcodebuild clean build -workspace TestApp.xcworkspace -scheme TestApp_v4_2 -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO | tee xcodebuild.log | xcpretty -r html || CODE=$?
  xcodebuild clean build -workspace TestApp.xcworkspace -scheme TestApp_v5 -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO | tee xcodebuild.log | xcpretty -r html || CODE=$?
  cd ../
  export CODE
}

libLint() {
  echo Linting the pod
  pod lib lint --fail-fast --allow-warnings
}

FLAG=$(mktemp)

if [ "$TRAVIS_EVENT_TYPE" == "cron" ] || [ -n "$TRAVIS_TAG" ]; then
  # Full build at night and tags
  keepAlive $FLAG &
  libLint
  
else
  # Else just build the test app
  buildiOSApp
fi

rm $FLAG  # stop keepAlive
