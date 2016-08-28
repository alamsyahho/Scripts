#!/bin/bash

SERVICE_NAME="$1"
ROLE="$2"
STATE="$3"
SLAVE_IP="$4"
SLAVE_PORT="$5"
MASTER_IP="$6"
MASTER_PORT="$7"

# Load balancer config
LB_HOST=<LB_IPADDR>
LB_USER=<LB_USER_AUTH>
LB_PASSWORD=<LB_AUTH_PASSWD>
VS_IPADDR=<VS_IP_ADDR>

# Email config
MAILGUN_DOMAIN="account.example.com"
MAILGUN_KEY="key-somerandonmailgunkey"
MAILFROM="alerts <alerts@example.com>"
MAILTO="admin@example.com"
MAILSUBJECT="Redis Notification $SERVICE_NAME"
MAILBODY=`cat << EOB
============================================
Redis Reconfig Script called by Sentinel
============================================
Event Type: ${SERVICE_NAME} ${STATE}
Event Description:
Enable $MASTER_IP on Virtual Service $SERVICE_NAME $VS_IPADDR:$MASTER_PORT
Disable $SLAVE_IP from Virtual Service $SERVICE_NAME $VS_IPADDR:$MASTER_PORT

Check the redis status.
EOB`

if [ $2 == "leader" ]; then

echo "Enable $MASTER_IP on Virtual Service $SERVICE_NAME $VS_IPADDR:$MASTER_PORT"
curl -k -silent -u $LB_USER:$LB_PASSWORD "https://$LB_HOST/access/modrs?vs=$VS_IPADDR&port=$MASTER_PORT&prot=tcp&rs=$MASTER_IP&rsport=$MASTER_PORT&enable=y" > /dev/null 2>&1

echo "Disable $SLAVE_IP from Virtual Service $SERVICE_NAME $VS_IPADDR:$MASTER_PORT"
curl -k -silent -u $LB_USER:$LB_PASSWORD "https://$LB_HOST/access/modrs?vs=$VS_IPADDR&port=$SLAVE_PORT&prot=tcp&rs=$SLAVE_IP&rsport=$SLAVE_PORT&enable=n" > /dev/null 2>&1

curl -s --user "api:${MAILGUN_KEY}" https://api.mailgun.net/v3/${MAILGUN_DOMAIN}/messages -F from="${MAILFROM}" -F to="${MAILTO}" -F subject="${MAILSUBJECT}" -F text="${MAILBODY}"

fi
