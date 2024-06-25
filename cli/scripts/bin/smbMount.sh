#!/bin/bash

# Create a folder to store the credentials for this storage account and
# any other that you might set up.
CREDENTIAL_ROOT="/etc/smbcredentials"
sudo mkdir -p "/etc/smbcredentials"

# Get the storage account key for the indicated storage account.
# You must be logged in with az login and your user identity must have 
# permissions to list the storage account keys for this command to work.
STORAGE_ACCOUNT_KEY=$(az storage account keys list \
    --resource-group $RESOURCE_GROUP_NAME \
    --account-name $STORAGE_ACCOUNT_NAME \
    --query "[0].value" --output tsv | tr -d '"')

# Create the credential file for this individual storage account
SMB_CREDENTIAL_FILE="$CREDENTIAL_ROOT/$STORAGE_ACCOUNT_NAME.cred"
if [ ! -f $SMB_CREDENTIAL_FILE ]; then
    echo "username=$STORAGE_ACCOUNT_NAME" | sudo tee $SMB_CREDENTIAL_FILE > /dev/null
    echo "password=$STORAGE_ACCOUNT_KEY" | sudo tee -a $SMB_CREDENTIAL_FILE > /dev/null
else 
    echo "The credential file $SMB_CREDENTIAL_FILE already exists, and was not modified."
fi

# Change permissions on the credential file so only root can read or modify the password file.
sudo chmod 600 $SMB_CREDENTIAL_FILE

HTTP_ENDPOINT=$(az storage account show \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $STORAGE_ACCOUNT_NAME \
    --query "primaryEndpoints.file" --output tsv | tr -d '"')
SMB_PATH=$(echo $HTTP_ENDPOINT | cut -c7-${#HTTP_ENDPOINT})$FILE_SHARE_NAME

if [ -z "$(grep $SMB_PATH\ $MNT_PATH /etc/fstab)" ]; then
    echo "$SMB_PATH $MNT_PATH cifs nofail,credentials=$SMB_CREDENTIAL_FILE,serverino,nosharesock,actimeo=30" | sudo tee -a /etc/fstab > /dev/null
else
    echo "/etc/fstab was not modified to avoid conflicting entries as this Azure file share was already present. You may want to double check /etc/fstab to ensure the configuration is as desired."
fi

sudo mount -a