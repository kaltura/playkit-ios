#!/bin/bash

set -u

cat << EOF > ~/.netrc
machine trunk.cocoapods.org
  login $PODS_USER
  password $PODS_PASS
EOF

chmod 0600 ~/.netrc

pod trunk push --verbose --allow-warnings
