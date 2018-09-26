#!/bin/bash


login() {
cat << EOF > ~/.netrc
machine trunk.cocoapods.org
  login $COCOAPODS_USERNAME
  password $COCOAPODS_PASSWORD
EOF

chmod 0600 ~/.netrc
}

# Travis aborts the build if it doesn't get output for a long while.
keepAlive() {
  while [ -f $FLAG ]
  do 
    sleep 5
    echo .
  done
}

FLAG=$(mktemp)

# If we're building a proper tag (v1.2.3), push to cocoapods. Else lint.
if [[ $TRAVIS_TAG =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
  login
  keepAlive & pod trunk push --allow-warnings
else
  keepAlive & pod lib lint --allow-warnings
fi

rm $FLAG

