#!/bin/bash

#Define the bucket name and the limit timestamp
bucket="S3_BUCKET_NAME"
limit=`date --date="1 month ago" +"%Y%m%d"`

echo `date '+%F %T'` - Timestamp of one month ago: $onemonthago
echo `date '+%F %T'` - Getting the list of available backups

total=0

for filename in `s3cmd ls s3://$bucket`; do
        if [[ $filename =~ ([0-9]*)\.7z ]]; then
                timestamp=${BASH_REMATCH[1]}
                echo `date '+%F %T'` - Reading metadata of: $filename
                echo -e "\tFilename: $filename"
                echo -e "\tTimestamp: $timestamp"
                if [[ $timestamp -le $limit ]]; then
                        let "total=total+1"
                        echo -e "\tResult: Backup deleted\n"
                        /usr/bin/s3cmd del $filename
                else
                        echo -e "\tResult: Backup keeped\n"
                fi
        fi
done

echo `date '+%F %T'` - $total old backups removed
