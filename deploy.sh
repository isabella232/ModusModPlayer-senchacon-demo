#!/bin/sh

target="testing";

buildDir="../build/$target"
androidDir="../android/assets/www"
iosDir="../ios/www"

echo $'\e[32m''building Sencha  ../ios/www' $'\e[00m'

#sencha app build testing ../ios/www/ > /tmp/st2.out
cd html5/
sencha app build $target >/tmp/st2.out 2>&1
# isError=`grep ERROR /tmp/st2.out > /dev/null 2>&1`
if [ $? -eq 0 ]; then
	echo $'\e[31m''Sencha build error' $'\e[00m'
	osascript -e 'tell application "Finder"' -e "activate" -e "display dialog \"Erorr with Sencha Touch 2 build\"" -e 'end tell'
	cat /tmp/st2.out
	cd ..
else 	
	echo $'\e[32m''Sencha build DONE' $'\e[00m'
	echo "Copying to android..."
	#rm -rf $androidDir/* 
	#cp -Rf $buildDir/* $androidDir/
	#cp lib/cordova-1.9.0.android.js $androidDir/cordova-1.9.0.js

	echo "Copying to ios..."
	rm -rf $iosDir/*
	cp -Rf $buildDir/* $iosDir/
	cp lib/cordova-1.9.0.ios.js $iosDir/cordova-1.9.0.js
	echo "DONE.."
fi
