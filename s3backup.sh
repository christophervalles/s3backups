#!/bin/bash

##
# To use the error functionality you have to redirect the output of this script
# to a file. If you are using a cron just check how it's done below.
#
# Remember that $backup_log must point to the file that we are redirecting
# the output on the cronjob
#
# Crontab example:
#
# 0 3 * * * /backups/scripts/s3backup.sh > /var/log/backups/s3backup.log 2>&1
# ----
# On the script $backup_log will point to /var/log/backups/s3backup.log
#
##

# Let shell functions inherit ERR trap.  Same as `set -E'.
set -o errtrace 

# Trigger error when expanding unset variables.  Same as `set -u'.
set -o nounset

#  Trap non-normal exit signals: 1/HUP, 2/INT, 3/QUIT, 15/TERM, ERR
#  NOTE1: - 9/KILL cannot be trapped.
#+        - 0/EXIT isn't trapped because:
#+          - with ERR trap defined, trap would be called twice on error
#+          - with ERR trap defined, syntax errors exit with status 0, not 2
#  NOTE2: Setting ERR trap does implicit `set -o errexit' or `set -e'.
trap onexit 1 2 3 15 ERR

#--- onexit() -----------------------------------------------------
#  @param $1 integer  (optional) Exit status.  If not set, use `$?'

function onexit() {
    #Send an email with the issue (using mail)
    echo -e "Something went wrong while doing a backup, below you'll find the log.\n" > $email_message
    echo -e "=====================================================================\n" >> $email_message
    cat $backup_log >> $email_message
    /usr/bin/mail -a "From: $email_from" -s "$email_subject" "$email_recipient" < $email_message

    ## Send an email with the issue (using sendmail)
    # echo -e "Subject:$email_subject\nFrom:$email_from\n" > $email_message
    # echo -e "Something went wrong while doing a backup, below you'll find the log.\n" >> $email_message
    # echo -e "=====================================================================\n" >> $email_message
    # cat $backup_log >> $email_message
    # /usr/sbin/sendmail -t $email_recipient < $email_message

    rm -Rf /backups/data/db/*
    rm -Rf /backups/data/www/*
    rm -Rf /backups/compressed/*

    local exit_status=${1:-$?}
    echo Exiting $0 with $exit_statusi
    exit $exit_status
}

#define email parameters
email_subject="Error while doing a backup"
email_recipient="THE RECIPIENT EMAIL"
email_from="THE FROM ADDRESS"
email_message="/tmp/backup_error_email.txt"

#backup params
backup_log="/var/log/backups/s3backup.log"

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

onexit