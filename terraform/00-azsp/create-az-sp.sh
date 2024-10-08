#!/bin/bash

set -euo pipefail

. ./00-azsp/spname.sh

# does sp-random.txt exist?
if [ -f ./sp-random.txt ]; then
  echo "sp-random.txt does not exists. Sure you want to continue?"
  echo "rm ./sp-random.txt , if you want to continue"
  exit 1
fi

echo $RANDOM | tee ./sp-random.txt
SPPREFIX=$(cat ./sp-random.txt)
SPID=$(az ad sp list --display-name "$SPPREFIX$SPNAME" --query "[].{id:appId}" -o tsv)
echo "Checked existing SP id: $SPID"

# stop id SPID exists (not empty string)
if [ -n "$SPID" ]; then
  echo "SP $SPPREFIX$SPNAME already exists, exiting"
  exit 1
fi

# create and note deployment credentials, where relevant
SUBSCRIPTION_ID=$(az account list -o json | jq -r '.[]|select(.isDefault)|.id')
echo "Subscription: $SUBSCRIPTION_ID"
# note credentials for config
AZCRED=$(az ad sp create-for-rbac --name "$SPPREFIX$SPNAME" --role="Owner" --scopes="/subscriptions/$SUBSCRIPTION_ID")
# echo "$AZCRED" | jq .
CLIENT_ID=$(echo "$AZCRED" | jq -r .appId)
CLIENT_SECRET=$(echo "$AZCRED" | jq -r .password)
TENANT_ID=$(echo "$AZCRED" | jq -r .tenant)

echo
echo 'Your input for terraform.tfvars'
echo "# SP $SPPREFIX${SPNAME}"
cat << EOF | tee sp.yaml 
sp:
  client_secret: "$CLIENT_SECRET"
  client_id: "$CLIENT_ID"
  tenant_id: "$TENANT_ID"
  subscription_id: "$SUBSCRIPTION_ID"

EOF

echo