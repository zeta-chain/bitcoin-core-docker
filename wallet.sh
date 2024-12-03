#!/bin/bash

generate_rpcauth_entry() {
  local user="$1"
  local password="$2"
  
  if [[ -z "$user" || -z "$password" ]]; then
      echo "Usage: generate_rpcauth_entry <user> <password>"
      return 1
  fi

  local salt
  local hashed_password
  salt=$(head -c 16 /dev/urandom | xxd -ps | tr -d '\n')
  hashed_password=$(echo -n "${password}" | openssl dgst -sha256 -hmac "${salt}" -binary | xxd -p -c 64)
  
  echo "rpcauth=${user}:${salt}\$${hashed_password}"
}

# set default config
# this makes running bitcoin-cli interactively much easier
# the admin user is the default user when running commands locally
# the rpc user is for remote usage

echo "
chain=${CHAIN}
rpcuser=${ADMIN_RPC_USER}
rpcpassword=${ADMIN_RPC_PASSWORD}
rpcallowip=0.0.0.0/0
$(generate_rpcauth_entry $ADMIN_RPC_USER $ADMIN_RPC_PASSWORD)
$(generate_rpcauth_entry $RPC_USER $RPC_PASSWORD)
rpcwhitelist=${RPC_USER}:getnetworkinfo,getbalance,sendrawtransaction,listunspent,estimatesmartfee,gettransaction,getrawtransaction,getblock,getblockhash,getblockheader,getblockcount,ping
rpcwhitelistdefault=0

[${CHAIN}]
rpcbind=0.0.0.0
">~/.bitcoin/bitcoin.conf

ensure_bitcoin_is_running() {
  process_check=`ps aux | grep -v grep | grep bitcoind`
  if [[ -z "${process_check}" ]]; then
    echo "Bitcoind seems to have crashed, we are going to ensure no lock exists on the process and restart the daemon."
    remove_lock_if_exists
    start_bitcoind_daemon
  fi
}

check_bitcoin_is_running() {
  process_check=`ps aux | grep -v grep | grep bitcoind`
  echo "${process_check}"
}

remove_lock_if_exists() {
  if [ -f "~/.bitcoin/bitcoind.pid" ]; then
    rm -rf ~/.bitcoin/bitcoind.pid || echo "Failed to delete PID"
  else
    echo "PID Doesn't Exist"
  fi

  if [ -f "~/.bitcoin/${CHAIN}/.lock" ]; then
   rm -rf ~/.bitcoin/${CHAIN}/.lock || echo "Failed to delete data lock"
  else
    echo "Failed to delete data lock"
  fi
}

start_bitcoind_daemon() {
  start_bitcoind -daemon
}

start_bitcoind() {
  bitcoind \
    -pid=${HOME}/.bitcoin/bitcoind.pid \
    -listen=1 \
    -server=1 \
    -txindex=1 \
    -deprecatedrpc=create_bdb \
    -deprecatedrpc=warnings \
    $@
}

stop_bitcoind_daemon() {
  bitcoin_pid=$(pgrep bitcoind)
  echo "Kill bitcoind with kill -SIGTERM"
  kill -SIGTERM "$bitcoin_pid"
  echo "bitcoind PID: ${bitcoin_pid}"
  while kill -0 "$bitcoin_pid" 2> /dev/null; do
    echo "Waiting for bitcoind process to stop."
    check_bitcoin_is_running
    sleep 1
  done
}

wait_for_daemon_active() {
  while true; do
    check_bitcoin_is_running
    if bitcoin-cli getblockchaininfo ; then
      return
    fi
    echo "Waiting for bitcoind to start..."
    sleep 5
  done
}

get_current_height() {
  if [[ -z $NETWORK_HEIGHT_URL ]]; then
    case $CHAIN in
      "main")
      NETWORK_HEIGHT_URL=https://mempool.space/api/blocks/tip/height
        ;;
      "testnet3")
        NETWORK_HEIGHT_URL=https://mempool.space/testnet/api/blocks/tip/height
        ;;
      "testnet4")
        NETWORK_HEIGHT_URL=https://mempool.space/testnet4/api/blocks/tip/height
        ;;
      "signet")
        NETWORK_HEIGHT_URL=https://mempool.space/signet/api/blocks/tip/height
        ;;
      "regtest")
        echo 0
        return
        ;;
      *)
        echo "Unsupported chain: $CHAIN" >&2
        return 1
        ;;
    esac
  fi
  curl -s ${NETWORK_HEIGHT_URL}
}

wait_for_network_sync() {
  echo "Wait until network is completely synced."
  while true
  do
    network_current_block=`get_current_height || echo "No height was observed. Waiting for external network to return check height."`
    node_current_block=`bitcoin-cli getblockchaininfo | jq -r '.blocks' || echo "No height was observed. Waiting for local network to return height."`
    if [[ "${node_current_block}" -ge "${network_current_block}" ]]; then
      echo "Bitcoin node is now synced, the local height is greater than or equal to the external height."
      break
    else
      echo "Node height: ${node_current_block} Network Height: ${network_current_block} - Network Still Syncing"
    fi
    sleep 30
  done
}

load_wallet() {
  bitcoin-cli -named createwallet wallet_name=${WALLET_NAME} disable_private_keys=true load_on_startup=true descriptors=false || echo "wallet exists"
  sleep 5
  bitcoin-cli loadwallet ${WALLET_NAME} || echo "wallet already loaded"
  sleep 5
  bitcoin-cli -rpcwallet="${WALLET_NAME}" importaddress "${WALLET_ADDRESS}" "${WALLET_NAME}" true || echo "importaddress failed"
}

snapshot_restore() {
  if [ "$SNAPSHOT_RESTORE" != "true" ]; then
    return
  fi

  if [ -f ~/.bitcoin/extracted ]; then
    echo "Snapshot already extracted. Skipping download and extraction."
    return
  fi

  echo "Use restore from snapshot: $SNAPSHOT_RESTORE"

  mkdir -p ~/.bitcoin/ || echo "already exists."
  cd ~/.bitcoin/
  rm -rf ~/.bitcoin/{$CHAIN}
  
  curl -L "${SNAPSHOT_URL}" | tar -xzf -
  touch ~/.bitcoin/extracted

  echo "Snapshot Restored. Verify the data and folder structure."
  echo "Bitcoin network snapshot restart process is complete."
}


echo "Remove Lock if Exists"
remove_lock_if_exists

echo "Check snapshot restore."
snapshot_restore

echo "Start Bitcoind Daemon"
start_bitcoind_daemon

echo "Wait for bitcoind to be active."
wait_for_daemon_active

echo "Wait for network sync."
wait_for_network_sync

echo "Ensure bitcoind is running."
ensure_bitcoin_is_running

echo "Wait for daemon active."
wait_for_daemon_active

echo "Load Wallet"
load_wallet

echo "Stop the daemon to start the non daemon forground process."
stop_bitcoind_daemon

echo "Check bitcoind is running."
check_bitcoin_is_running

echo "Start bitcoind foreground process"
start_bitcoind