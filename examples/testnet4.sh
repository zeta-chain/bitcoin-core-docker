#!/bin/bash

docker run -d \
  --name testnet4 \
  -e CHAIN=testnet4 \
  -e RPC_USER=default \
  -e RPC_PASSWORD=default \
  -e WALLET_NAME=default \
  -e WALLET_ADDRESS=110yMxB69Fp5kYQtdA7lpQWZWCMna2dtjl \
  bitcoin-core-docker /opt/wallet.sh