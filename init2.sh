#!/bin/bash

# Exit immediately if any command fails
set -e

# Configuration variables
KEY="localkey"
CHAINID="aigentest_3234423-1"
MONIKER="prod-node"
KEYRING="os"
LOGLEVEL="info"
TRACE=""

# Binary name and data directory
BINARY="./aigen"
DATA_DIR="./node"

# Check dependencies
command -v jq > /dev/null 2>&1 || { echo >&2 "jq is required but not installed. Install it and try again."; exit 1; }

# Remove any existing setup
echo "Cleaning up previous setup..."
rm -rf $DATA_DIR

# Configure CLI
echo "Configuring CLI..."
$BINARY config keyring-backend $KEYRING
$BINARY config chain-id $CHAINID

# Initialize the node
echo "Initializing node with moniker $MONIKER and chain ID $CHAINID..."
$BINARY init $MONIKER --chain-id $CHAINID --home $DATA_DIR

# Update genesis file for token denominations
GENESIS_FILE="$DATA_DIR/config/genesis.json"

echo "Updating genesis file for token denominations..."
jq '.app_state["staking"]["params"]["bond_denom"]="uaigent"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE
jq '.app_state["crisis"]["constant_fee"]["denom"]="uaigent"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE
jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="uaigent"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE
jq '.app_state["mint"]["params"]["mint_denom"]="uaigent"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE
jq '.app_state["evm"]["params"]["evm_denom"]="uaigent"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE

# Add mint parameters
jq '.app_state["mint"]["params"]["inflation_rate_change"]="0.000000000000000000"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE
jq '.app_state["mint"]["params"]["inflation_max"]="0.000000000000000000"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE
jq '.app_state["mint"]["params"]["inflation_min"]="0.000000000000000000"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE
jq '.app_state["mint"]["params"]["goal_bonded"]="0.670000000000000000"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE
jq '.app_state["mint"]["params"]["blocks_per_year"]="6311520"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE


if [[ $1 == "pending" ]]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOME/.haqqd/config/config.toml
      sed -i '' 's/timeout_propose = "3s"/timeout_propose = "30s"/g' $HOME/.haqqd/config/config.toml
      sed -i '' 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' $HOME/.haqqd/config/config.toml
      sed -i '' 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' $HOME/.haqqd/config/config.toml
      sed -i '' 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' $HOME/.haqqd/config/config.toml
      sed -i '' 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' $HOME/.haqqd/config/config.toml
      sed -i '' 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' $HOME/.haqqd/config/config.toml
      sed -i '' 's/timeout_commit = "5s"/timeout_commit = "150s"/g' $HOME/.haqqd/config/config.toml
      sed -i '' 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' $HOME/.haqqd/config/config.toml
  else
      sed -i 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOME/.haqqd/config/config.toml
      sed -i 's/timeout_propose = "3s"/timeout_propose = "30s"/g' $HOME/.haqqd/config/config.toml
      sed -i 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' $HOME/.haqqd/config/config.toml
      sed -i 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' $HOME/.haqqd/config/config.toml
      sed -i 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' $HOME/.haqqd/config/config.toml
      sed -i 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' $HOME/.haqqd/config/config.toml
      sed -i 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' $HOME/.haqqd/config/config.toml
      sed -i 's/timeout_commit = "5s"/timeout_commit = "150s"/g' $HOME/.haqqd/config/config.toml
      sed -i 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' $HOME/.haqqd/config/config.toml
  fi
fi

# # Set fixed total supply of 500M Aigent in smallest units (10^18)
# echo "Setting total supply to 500M Aigent (scaled to 10^18)..."
# TOTAL_SUPPLY="500000000000000000000000000"
# jq '.app_state["bank"]["supply"]=[{"denom":"uaigent","amount":"'"$TOTAL_SUPPLY"'"}]' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE


# Configure blocks and Prometheus
CONFIG_FILE="$DATA_DIR/config/config.toml"
APP_FILE="$DATA_DIR/config/app.toml"

sed -i 's/^timeout_commit = ".*"/timeout_commit = "3s"/' $CONFIG_FILE

if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/create_empty_blocks = true/create_empty_blocks = false/' $CONFIG_FILE
    sed -i '' 's/prometheus = false/prometheus = true/' $CONFIG_FILE
    sed -i '' 's/prometheus-retention-time = 0/prometheus-retention-time = 1000000000000/' $APP_FILE
    sed -i '' 's/enabled = false/enabled = true/' $APP_FILE
else
    sed -i 's/create_empty_blocks = true/create_empty_blocks = false/' $CONFIG_FILE
    sed -i 's/prometheus = false/prometheus = true/' $CONFIG_FILE
    sed -i 's/prometheus-retention-time = 0/prometheus-retention-time = 1000000000000/' $APP_FILE
    sed -i 's/enabled = false/enabled = true/' $APP_FILE
fi

if [[ $1 == "pending" ]]; then
    echo "pending mode is on, please wait for the first block committed."
    sed -i 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/' $CONFIG_FILE
    sed -i 's/timeout_propose = "3s"/timeout_propose = "30s"/' $CONFIG_FILE
    sed -i 's/timeout_commit = "5s"/timeout_commit = "150s"/' $CONFIG_FILE
fi


# Add genesis account with sufficient balance
echo "Adding genesis account..."
$BINARY keys add $KEY --keyring-backend $KEYRING  --home $DATA_DIR
$BINARY genesis add-genesis-account $KEY "500000000000000000000000000"uaigent --keyring-backend $KEYRING --home $DATA_DIR

# Generate and collect genesis transactions with sufficient delegation
echo "Generating and collecting genesis transactions..."
DELEGATION_AMOUNT="5000000000000000000" # 1 Aigent (scaled to 10^18)
$BINARY genesis gentx $KEY "$DELEGATION_AMOUNT"uaigent --keyring-backend $KEYRING --chain-id $CHAINID --home $DATA_DIR
$BINARY genesis collect-gentxs --home $DATA_DIR

# Validate the genesis file
echo "Validating genesis file..."
$BINARY genesis validate-genesis --home $DATA_DIR

# Display private key for Metamask
# echo -e "\n### Exporting private key for Metamask ###"
# $BINARY keys unsafe-export-eth-key $KEY --home=$DATA_DIR --keyring-backend $KEYRING

# Start the node
echo -e "\nStarting the node..."
$BINARY start \
  --pruning=nothing $TRACE \
  --log_level $LOGLEVEL \
  --minimum-gas-prices=1uaigent \
  --home $DATA_DIR
