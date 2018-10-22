#!/bin/bash

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

FLAG=$(mktemp)

keepAlive $FLAG &

# If we're building a release tag (v1.2.3), push to cocoapods, else lint.
if [[ $TRAVIS_TAG =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
  echo "Pushing to Trunk"
  login
  pod trunk push --allow-warnings
else
  echo "Linting the pod"
  pod lib lint --allow-warnings
fi

rm $FLAG  # stop keepAlive
echo "Cocoapods done"
