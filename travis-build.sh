#!/bin/bash

set -e -o pipefail

# Login to cocoapods trunk.
login() {
cat << EOF > ~/.netrc
machine trunk.cocoapods.org
  login $COCOAPODS_USERNAME
  password $COCOAPODS_PASSWORD
EOF

chmod 0600 ~/.netrc
}

# Travis aborts the build if it doesn't get output for 10 minutes.
keepAlive() {
  while [ -f $1 ]
  do 
    sleep 10
    echo .
  done
}

trunkPush() {
  FLAG=$(mktemp)
  keepAlive $FLAG &
  login
  pod trunk push --allow-warnings
  rm $FLAG  # stop keepAlive
}

justBuild() {
  cd TestApp
  pod install
  xcodebuild build -workspace TestApp.xcworkspace -scheme TestApp -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO | xcpretty
}

libLint() {
  FLAG=$(mktemp)
  keepAlive $FLAG &
  pod lib lint --allow-warnings
  rm $FLAG  # stop keepAlive
}


pod repo update

# If we're building a release tag (v1.2.3) push to cocoapods, else build TestApp.
if [[ $TRAVIS_TAG =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
  trunkPush
elif [ $TRAVIS_EVENT_TYPE == cron ]
  libLint
else
  justBuild
fi

