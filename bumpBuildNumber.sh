#!/bin/bash

PLISTBUDDY="/usr/libexec/PlistBuddy -c"
FILE="/Users/dirk/Dropbox/Development/iOS/Offtube/Offtube/Info.plist"

buildNumber=$($PLISTBUDDY "Print CFBundleVersion" "$FILE")
buildNumber=$(($buildNumber + 1))
$PLISTBUDDY "Set :CFBundleVersion $buildNumber" "$FILE"
echo 'Build:' $buildNumber
