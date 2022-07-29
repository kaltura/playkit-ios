#!/bin/bash

set -u

PODSPEC=*.podspec
POD=$(basename $PODSPEC .podspec)

pod ipc spec $POD.podspec > spec.json

POD_NAME=$(jq '.name' --raw-output spec.json)
VERSION=$(jq '.version' --raw-output spec.json)

sed -e "s#@@RELEASE_NOTES@@#- TBA#g" -e "s#@@POD_NAME@@#$POD_NAME#g" -e "s#@@POD_PREFERRED_VERSION@@#$VERSION#g" -i '' .github/release_notes_template.md

cat .github/release_notes_template.md
