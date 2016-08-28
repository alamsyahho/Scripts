#!/bin/bash
# Author: Anthony Chin
# Revision Date: 20110104
# Version: 1.1


#
# Declaration
#
CHECK_DIR="/home"
FILE_SIZE="50M"
# You may add addtional email account at the line below as EMAIL_TO="serveralert@abamon.com abc@abc.com"
EMAIL_TO="serveralert@example.com.com serveralert@example2.com" 
TMP_LOG="/tmp/filecheck.log"

echo "Date: `date`" > $TMP_LOG;
echo "Server: `hostname`" >> $TMP_LOG;
echo "Check Directory: $CHECK_DIR" >> $TMP_LOG;
echo "" >> $TMP_LOG;

# To show file larger than 50M
#
echo "File size larger than $FILE_SIZE" >> $TMP_LOG;
echo "-------------------------------------------------------" >> $TMP_LOG;
find $CHECK_DIR -type f -size +$FILE_SIZE -exec ls -lh {} \; >> $TMP_LOG;

#
# To show Directory with drwxrwxrwx (777) permission
#
echo "" >> $TMP_LOG;
echo "Directory with drwxrwxrwx (777) permission" >> $TMP_LOG;
echo "-------------------------------------------------------" >> $TMP_LOG;
find $CHECK_DIR -type d -perm 777 -exec ls -lhd {} \; >> $TMP_LOG;

#
# To show Files with drwxrwxrwx (777) permission
#
echo "" >> $TMP_LOG;
echo "Files with rwxrwxrwx (777) permission" >> $TMP_LOG;
echo "-------------------------------------------------------" >> $TMP_LOG;
find $CHECK_DIR -type f -perm 777 -exec ls -lh {} \; >> $TMP_LOG;

#
# Recommendations
#
echo "" >> $TMP_LOG;
echo "Recommendations" >> $TMP_LOG;
echo "-------------------------------------------------------" >> $TMP_LOG;
FULL_PERM_FILE="-rwxrwxrwx"
FULL_PERM_DIR="drwxrwxrwx"
CHECK_PERM_FILE=`grep ^-rwxrwxrwx $TMP_LOG | head -n1 | awk '{print $1}'`
CHECK_PERM_DIR=`grep ^drwxrwxrwx $TMP_LOG | head -n1 | awk '{print $1}'`

if [ "$CHECK_PERM_FILE" == "$FULL_PERM_FILE" ];
	then echo "You have files with -rwxrwxrwx (777) permission !!" >> $TMP_LOG;
	     echo "Please change the file  permission listed above to 755 or consult system administrator for assistant." >> $TMP_LOG;
elif [ "$CHECK_PERM_DIR" == "$FULL_PERM_DIR" ];
	then echo "You have directory with drwxrwxrwx (777) permission !!" >> $TMP_LOG;
	     echo "Please change the directory permission listed above to 755 or consult system administrator for assistant." >> $TMP_LOG;
else echo "Your files and directory was in good permission." >> $TMP_LOG;
fi

#
# To send mail out
#
cat $TMP_LOG | /bin/mail -s "$HOSTNAME  - File and Directory Check" $EMAIL_TO

#
# To remove TMP_LOG after use
#
rm -f $TMP_LOG

# End of File
