#!/bin/bash


#SERVER_NAME=`hostname -I | awk '{print $1}'`
SERVER_NAME=`curl ifconfig.me`

TIMESTAMP=$(date +"%F")
BACKUP_DIR="/root/backup/$TIMESTAMP"
MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump
SECONDS=0

#make sure storage enough when backup
/usr/bin/rclone -q --min-age 2w delete "$SERVER_NAME:$SERVER_NAME" #Remove all backups older than 14 days
/usr/bin/rclone -q rmdirs "$SERVER_NAME:$SERVER_NAME" #Remove all backups older than 14 days

mkdir -p "$BACKUP_DIR/mysql"

echo "Starting Backup Database";
databases=`$MYSQL -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql)"`

for db in $databases; do
    $MYSQLDUMP --force --opt $db | gzip > "$BACKUP_DIR/mysql/$db.gz"
done
echo "Finished";
/usr/bin/rclone move $BACKUP_DIR/mysql "$SERVER_NAME:$SERVER_NAME/$TIMESTAMP" >> /var/log/rclone.log 2>&1
rm -rf $BACKUP_DIR/mysql
echo '';

echo "Starting Backup Website";
# Loop through /home directory
for domain in /home/*/domains/*; do
    if [ -d "${domain}" ]; then #If a directory
        domain=${domain##*/} # Domain name
        echo "- "$domain;
        zip -r $BACKUP_DIR/${domain}.zip /home/*/domains/$domain/* -q -x '/home/*/domains/$domain/public_html/*.zip' -x '/home/*/domains/$domain/public_html/wp-content/cache/' -x '/home/*/domains/$domain/public_html/wp-content/uploads/backupbuddy_backups/' #Exclude cache
        echo "Finished";
        echo "Starting Uploading Backup";
        /usr/bin/rclone move $BACKUP_DIR/${domain}.zip "$SERVER_NAME:$SERVER_NAME/$TIMESTAMP" >> /var/log/rclone.log 2>&1
        rm -rf $BACKUP_DIR/*.zip
        echo '';
    fi
done

#/usr/bin/rclone -q --min-age 4w delete "remote:$SERVER_NAME" #Remove all backups older than 2 week
#/usr/bin/rclone -q --min-age 4w rmdirs "remote:$SERVER_NAME" #Remove all empty folders older than 2 week
#/usr/sbin/rclone cleanup "lepin:" #Cleanup Trash
echo "Finished";
#echo '';

duration=$SECONDS
echo "Total $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
