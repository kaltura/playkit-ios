#!/bin/bash

if [ $TRAVIS_TAG =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]
then
  # push to cocoapods, this also lints before
  login
  #pod trunk push --allow-warnings PlayKit.podspec
else
  # just lint
  pod lib lint --allow-warnings --verbose
fi

login() {
  cat << EOF > ~/.netrc
  machine trunk.cocoapods.org
    login $COCOAPODS_USERNAME
    password $COCOAPODS_PASSWORD
  EOF

  chmod 0600 ~/.netrc
}
