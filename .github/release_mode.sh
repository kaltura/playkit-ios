#!/bin/bash

set -u

PODSPEC=*.podspec
POD=$(basename $PODSPEC .podspec)

sed -e "s#.0000##1" -i '' $POD.podspec

cat $POD.podspec

git add .
git config user.name "Kaltura Dev"
git config user.email dev@kaltura.com

git commit -m "Set to release mode"

git push
