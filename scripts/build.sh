cd ..
target="testing";
projName=`cat html5/app.json | grep "\"name\"" | awk -F\" '{print $4}'`

echo "Building project: $projName"

buildDir="html5/build/$target/$projName"
cordovaDir="cordova/www"

echo $'\e[32m''building Sencha ' $'\e[00m'

cd html5/
ls
pwd
sencha app build $target
RC=$?
cd ..
# isError=`grep ERROR /tmp/st2.out > /dev/null 2>&1`
if [ $RC -ne 0 ]; then
	echo $'\e[31m''Sencha build error' $'\e[00m'
	cat /tmp/st2.out
	exit 1
else 	

	echo $'\e[32m''Sencha build DONE' $'\e[00m'

	echo `pwd`
	echo "Creating Cordova folder if not present."
	mkdir -p $cordovaDir

	echo "Erasing old contents from Cordova dir"
	rm -rf $cordovaDir/* 

	echo "Copying to Cordova..."
	cp -Rf $buildDir/* $cordovaDir/
	cp $cordovaDir/../www.orig/config.xml $cordovaDir/
	rm -rf $buildDir/

	echo ">>>> `pwd`"
	echo "Building Cordova iOS..."
	cd cordova
	echo ">>>> `pwd`"
	phonegap build ios

	echo $'\e[32m''DONE!' $'\e[00m'
	exit 0
fi

