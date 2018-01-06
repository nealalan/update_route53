## ADD THIS TO /etc/network/if-up.d TO RUN WHEN SYSTEM IS ON THE NETWORK
## NEAL DREHER 2018-01-03
#!/bin/bash
echo "ATTEMPTING TO UPDATE IP ADDRESS ON ROUTE53 DNS RECORD"
RECORD_SET="/tmp/change-resource-record-sets.json"
HOSTNAME=$(hostname -f)
echo "HOSTNAME: " $HOSTNAME
PUBLIC_IP=$(curl ipecho.net/plain)
echo "PUBLIC_IP: " $PUBLIC_IP
PROFILE_USED="--profile update_dns"
# Adjust the domain name as needed
echo "HOSTED_ZONE check / update..."
#HOSTED_ZONE=$(hostname | awk -F"." '{print $(NF-2)"."$(NF-1)"."$(NF)}')
HOSTED_ZONE=$(hostname)
echo "ZONE_ID CAPTURE"
ZONE_ID=$(aws route53 list-hosted-zones $PROFILE_USED | jq --arg hosted_zone $HOSTED_ZONE. '.HostedZones[]  | select(.Name == $hosted_zone) | .Id' | awk -F"/" '{print $3}' | tr -d "\"")
echo "RECORD_TYPE CAPTURE"
#RECORD_TYPE=$(aws route53 list-resource-record-sets $PROFILE_USED --hosted-zone-id $ZONE_ID --query "ResourceRecordSets[?Name == '$HOSTNAME.']" | jq ".[].Type" | tr -d "\"")
RECORD_TYPE="A"
echo "UPDATE_INFO CAPTURE"
UPDATE_INFO=$(date)

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
done

echo "Record updated!"
