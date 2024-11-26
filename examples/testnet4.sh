#!/bin/bash

docker run -d \
  --name testnet4 \
  -e CHAIN=testnet4 \
  -e RPC_USER=default \
  -e RPC_PASSWORD=default \
  -e WALLET_NAME=default \
  -e WALLET_ADDRESS=tb1qfm8a8pxer0kmfa4xlk34e44xpr8g46ae0v04dw \
  bitcoin-core-docker /opt/wallet.sh