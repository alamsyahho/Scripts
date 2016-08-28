#!/bin/bash

# Enable process checking or not. 1=enable 0=disable
ENABLE_SQS_RI="1"
ENABLE_SQS_JT="1"
ENABLE_SQS_QZ="1"
ENABLE_SQS_SJ="1"

# Number of each process worker
NO_OF_SQS_RI=1
NO_OF_SQS_JT=1
NO_OF_SQS_QZ=1
NO_OF_SQS_SJ=1

# User, path and variable for script
USER="pegipegi"
PROCESS_DIR="/home/pegipegi/git/api.pegipegi.com"
PROCESS_SQS_RI="artisan queue:listen sqs_RI"
PROCESS_SQS_JT="artisan queue:listen sqs_JT"
PROCESS_SQS_QZ="artisan queue:listen sqs_QZ"
PROCESS_SQS_SJ="artisan queue:listen sqs_SJ"

# ~~~~~~~~~~~~~~~~~ DONT CHANGE ANYTHING BELOW ~~~~~~~~~~~~~~~~~~~~~~~

PS=`which ps`
GREP=`which grep`
EGREP=`which egrep`
WC=`which wc`
SU=`which su`

export PATH=$PATH:/usr/local/bin

# Check and start SQS_RI process if below expected no of process

if [ $ENABLE_SQS_RI -eq 1 ];
then
        while [ `$PS aux|$GREP -i "$PROCESS_SQS_RI"|$EGREP -v grep|$WC -l` -lt $NO_OF_SQS_RI ]
        do
                echo "start process SQS_RI"
                cd $PROCESS_DIR; php $PROCESS_SQS_RI &
                sleep 5
        done
fi

# Check and start SQS_JT process if below expected no of process

if [ $ENABLE_SQS_JT -eq 1 ];
then
        while [ `$PS aux|$GREP -i "$PROCESS_SQS_JT"|$EGREP -v grep|$WC -l` -lt $NO_OF_SQS_JT ]
        do
                echo "start process SQS_JT"
                cd $PROCESS_DIR; php $PROCESS_SQS_JT &
                sleep 5
        done
fi

# Check and start SQS_QZ process if below expected no of process

if [ $ENABLE_SQS_QZ -eq 1 ];
then
        while [ `$PS aux|$GREP -i "$PROCESS_SQS_QZ"|$EGREP -v grep|$WC -l` -lt $NO_OF_SQS_QZ ]
        do
                echo "start process SQS_QZ"
                cd $PROCESS_DIR; php $PROCESS_SQS_QZ &
                sleep 5
        done
fi

# Check and start SQS_SJ process if below expected no of process

if [ $ENABLE_SQS_SJ -eq 1 ];
then
        while [ `$PS aux|$GREP -i "$PROCESS_SQS_SJ"|$EGREP -v grep|$WC -l` -lt $NO_OF_SQS_SJ ]
        do
                echo "start process SQS_SJ"
                cd $PROCESS_DIR; php $PROCESS_SQS_SJ &
                sleep 5
        done
fi

exit 0