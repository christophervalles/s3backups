Description
===========

This are two bash scripts to backup and maintain backups of your servers in Amazon S3

The system is built on top of 7zip and s3cmd.

The s3backup.sh script is in charge of dump several svn repos, mysql databases, some websites located at /var/www, the compress + encrypt the files in a 7zip archive and upload it to Amazon s3

The s3backup-maintenance takes cares about old backups (Keeping files of 1 month ago)

Usage
=====

Be sure you have s3cmd and 7zip installed and configured

1. You have to create a folder structure like this:

/backups
    /scripts
    /compressed
    /data
        /db
        /svn
        /www


2. Then put both scripts inside the scripts folder
3. Create a cron to run both scripts
