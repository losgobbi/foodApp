#!/bin/bash

#http://tgoode.com/2014/06/05/sensible-way-increment-bundle-version-cfbundleversion-xcode/

#branch=${1:-'master'}
branch=$(git rev-parse --abbrev-ref HEAD)
buildNumber=$(expr $(git rev-list $branch --count) - $(git rev-list HEAD..$branch --count))
echo "Updating build number to $buildNumber using branch '$branch'."
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
if [ -f "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}.dSYM/Contents/Info.plist" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}.dSYM/Contents/Info.plist"
fi
