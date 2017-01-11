#!/bin/bash

set -e

if [ "$TRAVIS_REPO_SLUG" == "kaltura/playkit-ios" ] && [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  
    jazzy # xcodebuild command is being run inside .jazzy.yaml script

    echo -e "Starting apple docs deploy...\n"

    # Get to the Travis build directory, configure git and clone the repo
    cd $TRAVIS_BUILD_DIR
    git config --global user.email "travis@travis-ci.org"
    git config --global user.name "travis-ci"
    git clone "https://$GITHUB_TOKEN@github.com/kaltura/playkit.git" gh-pages

    # Commit and Push the Changes
    cd gh-pages/docs/api
    git rm -rf ios
    mv $TRAVIS_BUILD_DIR/jazzy/docs ios
    git add -f .
    git commit -m "Latest appledoc on successful travis build $TRAVIS_BUILD_NUMBER auto-pushed to playkit-docs"
    #git push -fq origin master
    ls -l

    echo -e "deployed apple docs to playkit documentation\n"
else 
    echo -e "came from pull request or a fork, doing a regular build\n"
    xcodebuild -scheme PlayKitFramework -workspace PlayKitFramework.xcworkspace
fi
