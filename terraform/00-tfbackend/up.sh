#!/bin/bash
set -euxo pipefail

# does sa-random.txt exist?
if [ -f ./sa-random.txt ]; then
  echo "sa-random.txt does not exists. Sure you want to continue?"
  echo "rm ./sa-random.txt , if you want to continue"
  exit 1
fi

echo $RANDOM | tee ./sa-random.txt

# https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli

RESOURCE_GROUP_NAME=58-tfbackend
STORAGE_ACCOUNT_NAME="58tfbackend21745$(cat ./sa-random.txt)"
CONTAINER_NAME=tfstate

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location westeurope

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob --https-only true 

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME

echo "resource_group_name  = \"$RESOURCE_GROUP_NAME\""
echo "storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo "container_name       = \"$CONTAINER_NAME\""
echo "key                  = \"terraform.tfstate\""

#ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv) 
#echo export ARM_ACCESS_KEY=$ACCOUNT_KEY

cat << EOF 
    resource_group_name  = "$RESOURCE_GROUP_NAME"
    storage_account_name = "$STORAGE_ACCOUNT_NAME"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
EOF
