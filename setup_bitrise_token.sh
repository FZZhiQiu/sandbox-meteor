#!/bin/bash
read -p "Paste Bitrise Personal Access Token: " TOKEN
echo "$TOKEN" > .bitrise_token
echo "Token saved"
