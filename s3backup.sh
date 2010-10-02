#!/bin/bash

#define the bucket name and few passwords
bucket="S3_BUCKET_NAME"
db_password="MYSQL_PASSWORD"
compression_password="COMPRESSION_PASSWORD"

echo `date '+%F %T'`: Starting the backup

#Copy all the websites
echo `date '+%F %T'`: Starting the dump of websites
for i in /var/www/*/; do
	site=`basename $i`
	echo `date '+%F %T'`: Dumping site $site
	/usr/bin/7z a -mx6 -t7z /backups/data/www/$site.7z -p$compression_password /var/www/$site
	echo `date '+%F %T'`: Site $site dumped
done

#Dumping the DB
echo `date '+%F %T'`: Starting the dump of the DataBases
for i in /var/lib/mysql/*/; do
	db=`basename $i`
	echo `date '+%F %T'`: Dumping DB $db
	/usr/bin/mysqldump -uroot -p$db_password $db > /backups/data/db/$db.sql
	echo `date '+%F %T'`: Database $db dumped
done

#Compressing all the data
echo `date '+%F %T'`: Compressing the info
filename=$(date +%Y%m%d)
/usr/bin/7z a -mx6 -t7z /backups/compressed/$filename.7z -p$compression_password /backups/data/*
echo `date '+%F %T'`: Info compressed

#Upload to Amazon S3
echo `date '+%F %T'`: Uploading to Amazon S3
/usr/bin/s3cmd put --no-progress /backups/compressed/$filename.7z s3://$bucket/$filename.7z
echo `date '+%F %T'`: Upload completed

#Delete the local backups
echo `date '+%F %T'`: Cleaning up
rm -Rf /backups/data/svn/*
rm -Rf /backups/data/db/*
rm -Rf /backups/data/www/*
rm -Rf /backups/compressed/*
echo `date '+%F %T'`: Clean completed
echo `date '+%F %T'`: Backup completed
