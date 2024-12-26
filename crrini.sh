#!/bin/bash

# Exit immediately if any command fails
set -e

# Configuration variables
KEY="localkey"
CHAINID="aigentest_3234423-1"
MONIKER="genesis1"
KEYRING="os"
LOGLEVEL="info"
TRACE=""

# Binary name and data directory
BINARY="./aigen"
DATA_DIR="./node"
GENESIS_FILE="$DATA_DIR/config/genesis.json"
CONFIG_FILE="$DATA_DIR/config/config.toml"
APP_FILE="$DATA_DIR/config/app.toml"
DELEGATION_AMOUNT="1000000" # Adjust to meet DefaultPowerReduction

# Check dependencies
command -v jq > /dev/null 2>&1 || { echo "jq is required but not installed. Install it and try again."; exit 1; }

# Clean up previous setup
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
echo "Updating genesis file for token denominations..."
jq '.app_state["staking"]["params"]["bond_denom"]="aigent"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE
jq '.app_state["crisis"]["constant_fee"]["denom"]="aigent"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE
jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="aigent"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE
jq '.app_state["mint"]["params"]["mint_denom"]="aigent"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE
jq '.app_state["mint"]["params"]["inflation_rate_change"]="0.000000000000000000"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE
jq '.app_state["mint"]["params"]["inflation_max"]="0.000000000000000000"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE
jq '.app_state["mint"]["params"]["inflation_min"]="0.000000000000000000"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE
jq '.app_state["mint"]["params"]["goal_bonded"]="0.670000000000000000"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE
jq '.app_state["mint"]["params"]["blocks_per_year"]="6311520"' $GENESIS_FILE > $GENESIS_FILE.tmp && mv $GENESIS_FILE.tmp $GENESIS_FILE

# Configure node settings for blocks and Prometheus
echo "Configuring node settings..."
sed -i 's/^timeout_commit = ".*"/timeout_commit = "3s"/' $CONFIG_FILE
sed -i 's/create_empty_blocks = true/create_empty_blocks = false/' $CONFIG_FILE
sed -i 's/prometheus = false/prometheus = true/' $CONFIG_FILE
sed -i 's/enabled = false/enabled = true/' $APP_FILE
sed -i 's/prometheus-retention-time = 0/prometheus-retention-time = 1000000000000/' $APP_FILE

# Enable API and Swagger
echo "Enabling API and Swagger..."
sed -i 's/^enable = false/enable = true/' $APP_FILE
sed -i 's/^swagger = false/swagger = true/' $APP_FILE

# Add genesis account with sufficient balance
echo "Adding genesis account..."
$BINARY keys add $KEY --keyring-backend $KEYRING --home $DATA_DIR
$BINARY genesis add-genesis-account $KEY "500000000000000"aigent --keyring-backend $KEYRING --home $DATA_DIR

# Generate and collect genesis transactions
echo "Generating and collecting genesis transactions..."
$BINARY genesis gentx $KEY "$DELEGATION_AMOUNT"aigent --keyring-backend $KEYRING --chain-id $CHAINID --home $DATA_DIR
$BINARY genesis collect-gentxs --home $DATA_DIR

# Validate the genesis file
echo "Validating genesis file..."
$BINARY genesis validate-genesis --home $DATA_DIR

# Start the node
echo "Starting the node..."
$BINARY start \
  --pruning=nothing $TRACE \
  --log_level $LOGLEVEL \
  --minimum-gas-prices=0.01aigent \
  --home $DATA_DIR


# Re-enter keyring passphrase:

# - address: ai17jyzr9hatsmus7j6djp7xssl04k7wdlrrkj776
#   name: localkey
#   pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Aur8yH9+3xSF3mcKgi4jL15xSI80llQRMf/pFzBVkB9a"}'
#   type: local


# **Important** write this mnemonic phrase in a safe place.
# It is the only way to recover your account if you ever forget your password.

# shell legal dish always spy book knock ghost walnut fantasy parade rapid start correct image order arrive pledge deputy trouble ship crash time divide
