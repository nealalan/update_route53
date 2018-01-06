#!/bin/bash
# /etc/init.d/update_route53.sh
# chkconfig: 234 99 50
# description: Update the AWS Route 53 A record with the current IP address
# processname: update_route53.sh
#
# http://www.tldp.org/HOWTO/HighQuality-Apps-HOWTO/boot.html#boot.script
#
# VARS
# AWS_ACCESS_KEY_ID = 
# AWS_SECRET_ACCESS_KEY = 
#
echo USER=$(whoami)
echo AWS.credentials.update_dns=$(aws configure list --profile update_dns)
echo ""
echo "ATTEMPTING TO UPDATE IP ADDRESS ON ROUTE53 DNS RECORD"
RECORD_SET="/tmp/change-resource-record-sets.json"
HOSTNAME=$(hostname -f)
echo "Getting public IP address..."
PUBLIC_IP=$(curl https://ifconfig.co)
PROFILE_USED="--profile update_dns"
HOSTED_ZONE=$(hostname)
echo "Getting route53 zone id..."
ZONE_ID=$(aws route53 list-hosted-zones --profile update_dns | jq --arg hosted_zone neonaluminum.com. '.HostedZones[]  | select(.Name == "neonaluminum.com.") | .Id' | awk -F"/" '{print $3}' | tr -d "\"")
RECORD_TYPE="A"
UPDATE_INFO=$(date)

start() {

if [ -e "$RECORD_SET" ]
then
  echo "COMMAND: rm -f " $RECORD_SET
  rm -f $RECORD_SET
fi
echo "Updating resource record set"
echo "
{
    \"Comment\": \"Update record to reflect new public IP address\",
    \"Changes\": [
        {
            \"Action\": \"UPSERT\",
            \"ResourceRecordSet\": {
                \"Name\": \"$HOSTNAME.\",
                \"Type\": \"$RECORD_TYPE\",
                \"TTL\": 300,
                \"ResourceRecords\": [
                    {
                        \"Value\": \"$PUBLIC_IP\"
                    }
                ]
            }
        }
    ]
}" | tee -a /tmp/change-resource-record-sets.json

echo "CHANGE_ID..."
CHANGE_ID=$(aws route53 change-resource-record-sets $PROFILE_USED --hosted-zone-id $ZONE_ID --change-batch file:///$RECORD_SET | jq ".ChangeInfo.Id" | awk -F"/" '{print $3}' | tr -d "\"")
echo "CHANGE_STATUS..."
CHANGE_STATUS=$(aws route53 get-change $PROFILE_USED --id $CHANGE_ID | jq ".ChangeInfo.Status" | tr -d "\"")
declare -i COUNT=0

while [ "$CHANGE_STATUS" == "PENDING" ]
do
  COUNT=COUNT+1
  if [ "$COUNT" -ge 6 ]
  then
    echo "Update timed out, exiting..."
    exit 1
  fi
    sleep 10
    CHANGE_STATUS=$(aws route53 get-change $PROFILE_USED --id $CHANGE_ID | jq ".ChangeInfo.Status" | tr -d "\"")
    echo $CHANGE_STATUS
done
echo "Record updated!"
}

case "$1" in
	start)
		start
		;;
	*)
		echo $"Please use: /etc/inid.d/update_route53.sh start"
		exit 1
esac
exit 0
