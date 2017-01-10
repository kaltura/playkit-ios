#!/bin/bash
if [ -n "$TRAVIS_TAG" ] && [ "$TRAVIS_REPO_SLUG" == "kaltura/playkit-ios" ] && [ "$TRAVIS_PULL_REQUEST" == "false" ] && [ "$TRAVIS_BRANCH" == "master" ]; then
  
  echo -e "Starting apple docs deploy...\n"

  # Get to the Travis build directory, configure git and clone the repo
  cd $TRAVIS_BUILD_DIR
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "travis-ci"
  git clone --quiet --branch = playkit-docs https://${GITHUB_TOKEN}@github.com/kaltura/playkit master

  # Commit and Push the Changes
  cd master/docs/ios/
  git rm -rf ./
  cp -Rf $TRAVIS_BUILD_DIR/jazzy/docs ./
  git add -f .
  git commit -m "Latest appledoc on successful travis build $TRAVIS_BUILD_NUMBER auto-pushed to playkit-docs"
  git push -fq origin playkit-docs

  echo -e "deployed apple docs to playkit documentation\n"

fi