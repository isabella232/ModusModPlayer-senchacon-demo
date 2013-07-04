#!/bin/sh

MD5=`md5 /tmp/watcher.md5 | awk '{print $4}'`;
X=0;

while [ $X -eq 0 ]; do 
	newMD5=`ls -altR html5/ | grep -v app.json | grep -v iml> /tmp/watcher.md5 && md5 /tmp/watcher.md5 | awk '{print $4}'`;

	if [[ "$MD5" != "$newMD5" ]]; then
		echo 
		echo "Change found, deploying! `date`"
		say "deploying..."
		./deploy.sh
		if [ $? -eq 0 ] ; then
			MD5=$newMD5;
		fi
		say "done building" >/dev/null 2>&1
	else 
		printf .	
	fi
	
	sleep .5
done
