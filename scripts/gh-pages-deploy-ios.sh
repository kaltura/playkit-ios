#!/bin/bash

set -e

if [ "$TRAVIS_REPO_SLUG" == "kaltura/playkit-ios" ] && [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  
    jazzy # xcodebuild command is being run inside .jazzy.yaml script

    echo "Starting apple docs deploy..."

    # Get to the Travis build directory, configure git and clone the repo
    cd $TRAVIS_BUILD_DIR
    git config --global user.email "travis@travis-ci.org"
    git config --global user.name "travis-ci"
    git clone "https://$GITHUB_TOKEN@github.com/kaltura/playkit.git" gh-pages > /dev/null 2>&1

    # Commit and Push the Changes
    cd gh-pages/docs/api
    git rm -rf ios
    mv $TRAVIS_BUILD_DIR/jazzy/docs ios
    git add -f .
    git commit -m "Latest apple doc was created on successful travis build #$TRAVIS_BUILD_NUMBER, auto-pushed to playkit docs"
    #git push -fq origin master
    
    echo -e "\nfiles added in the commit:\n"
    ls -l ios

    echo "deployed apple docs to playkit documentation"
else 
    echo "came from pull request or a fork, doing a regular build"
    xcodebuild -scheme PlayKitFramework -workspace PlayKitFramework.xcworkspace
fi
