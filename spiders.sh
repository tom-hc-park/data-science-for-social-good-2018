#!/bin/bash

echo "Running spiders.py" 
cd /zfs/users/asda11/asda11/DSSG-2018_Housing/rental_crawlers
if python3.6 run_spiders.py; then 
	printf "Success on $(date +%F) \n" >> /zfs/users/asda11/asda11/logs/log.txt
else 
	printf "FAILED on $(date +%F) \n" >> /zfs/users/asda11/asda11/logs/log.txt
fi

DATE=`date +%Y-%m`
if [ $(date +%d) == 01 ]
then 
	/bin/git add "results/raw/listings-*.csv" 
fi

/bin/git pull 
/bin/git commit -a -m "Autocommit after running the shell script on $(date +%F)" 
/bin/git push -u origin master
