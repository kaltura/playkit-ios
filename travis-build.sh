#!/bin/bash

if [ "$TRAVIS_EVENT_TYPE" == "cron" ] || [ -n "$TRAVIS_TAG" ]; then
  # Full build at night and tags
  pod lib lint --fail-fast --allow-warnings
  
else
  # Else just build the test app
  curl https://kaltura.github.io/fe-tools/ios/pod-app/create.sh | bash -s - "pod 'PlayKit', :path => '..'"
  cd HelloPod
  pod install --repo-update
  xcodebuild -workspace HelloPod.xcworkspace -scheme HelloPod -sdk iphonesimulator
fi
