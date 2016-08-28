#/bin/bash

#Version: 0.1
#Summary: Checking file size over 5000k
#Run this script as root

CHECK_DIRS="/home"
DEPTH="15"
OUTPUT_DIRS="/tmp"
EMAIL_TO="alert@example.com"

/bin/ls -s1hgo `/usr/bin/find $CHECK_DIRS -depth -maxdepth $DEPTH -size +5000k` > $OUTPUT_DIRS/5000k
/bin/cat $OUTPUT_DIRS/5000k | /bin/mail -s "$HOSTNAME  - File over 5000k" $EMAIL_TO
