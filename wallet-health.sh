#!/bin/bash

set -eo pipefail

wallet_name=default
if [[ -n $1 ]]; then
  wallet_name=$1
fi

# this script checks if a wallet exists and is not scanning

echo "Getting wallet info"
wallet_info=$(bitcoin-cli -rpcwallet=${wallet_name} getwalletinfo)

if [[ $(echo "$wallet_info" | jq -r '.scanning') == "true" ]]; then
  echo "Error: Wallet is currently scanning" >&2
  exit 1
fi
