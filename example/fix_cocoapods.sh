#! /bin/sh
flutter clean
rm -Rf ios/Podfile.lock
rm -Rf ios/Pods
rm -Rf ios/.symlinks
rm -Rf ios/Flutter/Flutter.framework
rm -Rf ios/Flutter/Flutter.podspec
flutter pub get
cd ios || exit
pod install --repo-update
cd .. || exit