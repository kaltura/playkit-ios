#!/bin/bash

set -u

PODSPEC=*.podspec
POD=$(basename $PODSPEC .podspec)

pod ipc spec $POD.podspec > spec.json

TARGET_TAG=$(jq '.source.tag' --raw-output spec.json)
NAME=$(jq '.name' --raw-output spec.json)
COMMIT_SHA=$(git rev-parse HEAD)

cat << EOF > post.json
{
  "ref": "refs/tags/$TARGET_TAG",
  "sha": "$COMMIT_SHA"
}
EOF

POST_URL=https://api.github.com/repos/$GITHUB_REPOSITORY/git/refs

curl $POST_URL -X POST -H "Content-Type: application/json" -H "authorization: Bearer $GITHUB_TOKEN" -d@post.json

#Add current tag to job output
echo "::set-output name=tag::$TARGET_TAG"

echo "$NAME release tag added and it is ready for CocoaPods distribution, upcoming version is going to be $TARGET_TAG"
