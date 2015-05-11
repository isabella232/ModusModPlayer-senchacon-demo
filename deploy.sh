 #!/bin/sh

target="testing";
projName=`cat html5/app.json | grep "\"name\"" | awk -F\" '{print $4}'`

cwd=`pwd`

cordova="$cwd/node_modules/.bin/cordova"
buildDir="html5/build/$target/$projName"
iosDir="KGMP/www"
cordovaSrc="KGMP/platforms/ios/platform_www"

sencha="$cwd/sencha_cmd/sencha-5.1.3.61"

echo $'\e[32m'"building Sencha  ../$iosDir" $'\e[00m'

#sencha app build testing ../ios/www/ > /tmp/st2.out
cd html5/

# ~/bin/Sencha/Cmd/3.1.2.342/sencha app build $target
$sencha app build $target
RC=$?

cd ..

# isError=`grep ERROR /tmp/st2.out > /dev/null 2>&1`
if [ $RC -ne 0 ]; then
	echo $'\e[31m''Sencha build error' $'\e[00m'
	osascript -e 'tell application "Finder"' -e "activate" -e "display dialog \"Erorr with Sencha Touch 2 build\"" -e 'end tell'
	cat /tmp/st2.out
	cd ..
else 	
	echo $'\e[32m''Sencha build DONE' $'\e[00m'

	echo "Copying to ios..."

	rm -rf $iosDir/*
	cp -Rf "$buildDir/" $iosDir
	cp $cordovaSrc/cordova.js $iosDir/

	rm -rf $buildDir
	cd $cwd/KGMP
	$cordova prepare ios
	cp "$cwd/html5/config.custom.xml" "$cwd/KGMP/platforms/ios/KeygenMusicPlayer/config.xml"

	echo "DONE.."
	say "done"
fi
