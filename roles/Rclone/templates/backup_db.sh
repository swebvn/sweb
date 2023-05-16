#!/bin/bash


#SERVER_NAME=`hostname -I | awk '{print $1}'`
SERVER_NAME=`curl ifconfig.me`

TIMESTAMP=$(date +"%F")
BACKUP_DIR="/root/backup/$TIMESTAMP"
MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump
SECONDS=0

#make sure storage enough when backup
#/usr/bin/rclone -q --min-age 1w delete "$SERVER_NAME:$SERVER_NAME" #Remove all backups older than 14 days
#/usr/bin/rclone -q rmdirs "$SERVER_NAME:$SERVER_NAME" #Remove all backups older than 14 days

mkdir -p "$BACKUP_DIR/mysql"

echo "Starting Backup Database";
databases=`$MYSQL -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql)"`

for db in $databases; do
    $MYSQLDUMP --force --opt $db | gzip > "$BACKUP_DIR/mysql/$db.gz"
done
echo "Finished";
/usr/bin/rclone move $BACKUP_DIR/mysql "$SERVER_NAME:$SERVER_NAME/${TIMESTAMP}_db" >> /var/log/rclone.log 2>&1
rm -rf $BACKUP_DIR/mysql
echo '';

echo "Finished";
#echo '';

duration=$SECONDS
echo "Total $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
