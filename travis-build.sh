#!/bin/bash

if [[ $TRAVIS_TAG =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
  # push to cocoapods, this also lints before
  login
  CMD="trunk push"
else
  # just lint
  CMD="lib lint"
fi

echo Executing pod $CMD

# Travis aborts the build if it doesn't get output for a long while.
FLAG=$(mktemp)
pod $CMD --allow-warnings && rm $FLAG & while [ -f $FLAG ]; do sleep 5; echo . ; done;

login() {
cat << EOF > ~/.netrc
machine trunk.cocoapods.org
  login $COCOAPODS_USERNAME
  password $COCOAPODS_PASSWORD
EOF

chmod 0600 ~/.netrc
}
