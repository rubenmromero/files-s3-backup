#!/bin/bash

#
# Commands Definition
#
[[ -s /bin/awk ]] && AWK=/bin/awk || AWK=/usr/bin/awk
ECHO="/bin/echo -e"
[[ -s /bin/find ]] && FIND=/bin/find || FIND=/usr/bin/find
GREP=/bin/grep
HEAD=/usr/bin/head
RM="/bin/rm -vf"
SED=/bin/sed
TAR="/bin/tar cvfz"
WC="/usr/bin/wc -l"

# Comandos de AWS
AWS_S3_CP="/usr/bin/aws s3 cp"
AWS_S3_LS="/usr/bin/aws s3 ls"
AWS_S3_RM="/usr/bin/aws s3 rm"

#
# Variables Definition
#
CONF_FILE=$(dirname $0)/../conf/files_to_S3.conf
WORKSPACE=/

#
# Check the user used for the script execution
#
if [[ $(whoami) != 'root' ]]
then
   $ECHO "\nThe script must be executed by root user\n"
   exit 1
fi

#
# Configuration File Import
#
. $CONF_FILE

#
# Function to rotate the backup files in local and S3
#
rotate_backups ()
{
   # Delete the local backup files older than value set in NUM_DAYS_LOCAL variable
   $ECHO "\nDelete old backup files from local storage:"
   $FIND $BACKUPS_DIR -name "${BACKUP_PREFIX}-*.tar*" -mtime +$NUM_DAYS_LOCAL -exec $RM {} \;
   
   # Delete the S3 backup files older than value set in NUM_DAYS_S3 variable
   $ECHO "\nDelete old backup files from S3 storage:"
   NUM_BACKUPS_S3=$($AWS_S3_LS ${S3_FOLDER}/ |$GREP "${BACKUP_PREFIX}-.*\.tar\.*" |$WC)
   if [[ $NUM_BACKUPS_S3 -gt $NUM_DAYS_S3 ]]
   then
      NUM_FILES_DEL=$(($NUM_BACKUPS_S3 - $NUM_DAYS_S3))
      LIST_FILES_DEL=$($AWS_S3_LS ${S3_FOLDER}/ |$GREP "${BACKUP_PREFIX}-.*\.tar\.*" |$HEAD -$NUM_FILES_DEL |$AWK '{print $4}')
      for FILE in $LIST_FILES_DEL
      do
         $AWS_S3_RM ${S3_FOLDER}/$FILE
      done
   fi
}

#
# Main
#

# Prepare the execution
BACKUP_FILE=${BACKUPS_DIR}/$BACKUP_NAME
S3_FOLDER=$($ECHO $S3_FOLDER |$SED "s/\/$//g")

# Process the BACKUP_LIST variable turning absolute paths in relative paths for create the TAR file
BACKUP_LIST=$($ECHO "$BACKUP_LIST" |$SED "s/^\| / ./g")

# Create the TAR file containing the directories and files included in BACUKP_LIST variable
$ECHO "\nCreate '$BACKUP_NAME' backup containing the directories and files listed bellow:"
cd $WORKSPACE
if [[ -z $EXCLUDE_LIST ]]
then
   $TAR $BACKUP_FILE $BACKUP_LIST
else
   EXCLUDE_LIST=$($ECHO "$EXCLUDE_LIST" |$SED "s/^\| / --exclude ./g")
   $TAR $BACKUP_FILE $BACKUP_LIST $EXCLUDE_LIST
fi

# Send to S3 the compressed TAR file
$ECHO "\nSend the created '$BACKUP_NAME' file to '${S3_FOLDER}/' S3 path:"
$AWS_S3_CP $BACKUP_FILE ${S3_FOLDER}/

# Delete old backup files from local and S3 storage
$ECHO "\nBackup files rotation:"
rotate_backups
$ECHO
