#!/bin/bash

set -eo pipefail

# this script checks if a wallet exists and is not scanning

echo "Getting wallet info"
wallet_info=$(bitcoin-cli -rpcwallet=$1 getwalletinfo)

if [[ $(echo "$wallet_info" | jq -r '.scanning') == "true" ]]; then
  echo "Error: Wallet is currently scanning" >&2
  exit 1
fi
