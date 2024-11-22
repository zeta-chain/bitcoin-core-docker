# bitcoin-core-docker

This is a hard fork of [ruimarinho/docker-bitcoin-core](https://github.com/ruimarinho/docker-bitcoin-core) with support for new bitcoin core versions.

## `wallet.sh`

We also include a script which can start a bitcoin rpc node with a wallet in watch only mode. We require this functionality for our [observer/signer nodes](https://github.com/zeta-chain/node).

This script is stored at `/opt/wallet.sh`.

You should set several environment variables when running this container:

| variable    | description |
| -------- | ------- |
| `CHAIN`       | `chain` config setting. Allowed values: main, test, testnet4, signet, regtest.   |
| `RPC_USER`   | `rpcuser` config setting. |
| `RPC_PASSWORD` | `rpcpassword` config setting.   |
| `WALLET_NAME` | name of the wallet for the `createwallet` and `loadwallet` commands |
| `WALLET_ADDRESS` | address of the wallet |
| `NETWORK_HEIGHT_URL` | url which will return the current height of the network. Will use mempool.space if unset. |

ID mapping:

| chain | zetachain chain ID | port |
| -------- | ------- | --- |
| `main`     |  8332 | 8332 |
| `testnet3` | 18332 | 18332 |
| `regtest`  | 18444 | 18443 |
| `signet`   | 18333 | 38332 |
| `testnet4` | 18334 | 48332 |
