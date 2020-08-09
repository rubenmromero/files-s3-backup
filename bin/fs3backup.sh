#!/bin/bash

#
# Commands Definition
#
AWK=$([[ -s /bin/awk ]] && echo /bin/awk || echo /usr/bin/awk)
ECHO="/bin/echo -e"
GREP=/bin/grep
HEAD=/usr/bin/head
LS=$([[ -s /bin/ls ]] && echo /bin/ls || echo /usr/bin/ls)
MKDIR="$([[ -s /bin/mkdir ]] && echo /bin/mkdir || echo /usr/bin/mkdir) -p"
RM="/bin/rm -vf"
SED=/bin/sed
TAR="/bin/tar cvfz"
WC="/usr/bin/wc -l"

# AWS Commands
AWS=$([[ -s  /usr/bin/aws ]] && echo /usr/bin/aws || echo /usr/local/bin/aws)
AWS_S3_CP="$AWS s3 cp"
AWS_S3_LS="$AWS s3 ls"
AWS_S3_MB="$AWS s3 mb"
AWS_S3_RM="$AWS s3 rm"

#
# Variables Definition
#
CONF_FILE=$(dirname $0)/../conf/fs3backup.conf
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
# Configuration Import
#
. $CONF_FILE

BACKUP_FILE=${BACKUP_NAME_PREFIX}-${BACKUP_NAME_SUFFIX}.tar.gz
BACKUP_FILE_PATH=${BACKUPS_PATH}/${BACKUP_FILE}
BACKUP_FILE_PATH_PATTERN=${BACKUPS_PATH}/${BACKUP_NAME_PREFIX}-*.tar.gz
BACKUP_FILE_S3_PATTERN=${BACKUP_NAME_PREFIX}-.*\.tar\.gz
S3_BACKUPS_PATH=$($ECHO $S3_BACKUPS_PATH |$SED "s/\/$//g")

#
# Function to rotate the backup files in local and S3
#
rotate_backups ()
{
    # Delete the local backup files older than value set in NUM_COPIES_LOCAL variable
    $ECHO "\nDelete old backup files from local storage:"
    NUM_BACKUPS_LOCAL=$($LS $BACKUP_FILE_PATH_PATTERN |$WC)
    if [[ $NUM_BACKUPS_LOCAL -gt $NUM_COPIES_LOCAL ]]
    then
        NUM_FILES_DEL=$(($NUM_BACKUPS_LOCAL - $NUM_COPIES_LOCAL))
        LIST_FILES_DEL=$($LS $BACKUP_FILE_PATH_PATTERN |$HEAD -$NUM_FILES_DEL)
        for FILE in $LIST_FILES_DEL
        do
            $RM $FILE
        done
    fi

    # Delete the S3 backup files older than value set in NUM_COPIES_S3 variable
    $ECHO "\nDelete old backup files from S3 storage:"
    NUM_BACKUPS_S3=$($AWS_S3_LS ${S3_BACKUPS_PATH}/ |$GREP "${BACKUP_FILE_S3_PATTERN}" |$WC)
    if [[ $NUM_BACKUPS_S3 -gt $NUM_COPIES_S3 ]]
    then
        NUM_FILES_DEL=$(($NUM_BACKUPS_S3 - $NUM_COPIES_S3))
        LIST_FILES_DEL=$($AWS_S3_LS ${S3_BACKUPS_PATH}/ |$GREP "${BACKUP_FILE_S3_PATTERN}" |$HEAD -$NUM_FILES_DEL |$AWK '{print $4}')
        for FILE in $LIST_FILES_DEL
        do
            $AWS_S3_RM ${S3_BACKUPS_PATH}/$FILE
        done
    fi
}

#
# Main
#

# Create the local and S3 backup folders if they don't exist
$MKDIR $BACKUPS_PATH
[[ $($AWS_S3_LS $S3_BACKUPS_PATH 2>/dev/null) ]] || $AWS_S3_MB $S3_BACKUPS_PATH 1>/dev/null

# Process the BACKUP_LIST variable turning absolute paths in relative paths for create the TAR file
BACKUP_LIST=$($ECHO "$BACKUP_LIST" |$SED "s/^\| / ./g")

# Create the TAR file containing the directories and files included in BACUKP_LIST variable
$ECHO "\nCreate '$BACKUP_FILE' backup containing the directories and files listed bellow:"
cd $WORKSPACE
if [[ -z $EXCLUDE_LIST ]]
then
    $TAR $BACKUP_FILE_PATH $BACKUP_LIST
else
    EXCLUDE_LIST=$($ECHO "$EXCLUDE_LIST" |$SED "s/^\| / --exclude ./g")
    $TAR $BACKUP_FILE_PATH $BACKUP_LIST $EXCLUDE_LIST
fi

# Send to S3 the compressed TAR file
$ECHO "\nSend the created '$BACKUP_FILE' file to '${S3_BACKUPS_PATH}/' S3 path:"
$AWS_S3_CP $BACKUP_FILE_PATH ${S3_BACKUPS_PATH}/

# Delete old backup files from local and S3 storage
$ECHO "\nBackup files rotation:"
rotate_backups
$ECHO
