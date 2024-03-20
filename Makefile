# Makefile for Foundry Ethereum Development Toolkit

.PHONY: build test format snapshot anvil deploy deploy-anvil cast help subgraph

build:
	@echo "Building with Forge..."
	@forge build

test:
	@echo "Testing with Forge..."
	@forge test

format:
	@echo "Formatting with Forge..."
	@forge fmt

snapshot:
	@echo "Creating gas snapshot with Forge..."
	@forge snapshot

anvil:
	@echo "Starting Anvil local Ethereum node..."
	@anvil

deploy-anvil:
	@echo "Deploying with Forge to Anvil..."
	@forge create ./src/Forwarder.sol:Forwarder --rpc-url anvil --interactive | sed 's/Deployed to:/Deployed Forwarder to:/' | tee deployment-anvil.txt
	@forge create ./src/GenericTokenMeta.sol:GenericTokenMeta --rpc-url anvil --interactive --constructor-args "GenericTokenMeta" "GTM" "$$(grep "Deployed Forwarder to:" deployment-anvil.txt | awk '{print $$4}')" | sed 's/Deployed to:/Deployed GenericTokenMeta to:/' | tee -a deployment-anvil.txt

deploy:
	@eval $$(curl -H "x-auth-token: $${BTP_SERVICE_TOKEN}" -s $${BTP_CLUSTER_MANAGER_URL}/ide/foundry/$${BTP_SCS_ID}/env | sed 's/^/export /'); \
	if [ -z "$${BTP_FROM}" ]; then \
		echo "\033[1;33mWARNING: No keys are activated on the node, falling back to interactive mode...\033[0m"; \
		echo ""; \
		if [ -z "$${BTP_GAS_PRICE}" ]; then \
			forge create ./src/Forwarder.sol:Forwarder $${EXTRA_ARGS} --rpc-url $${BTP_RPC_URL} --interactive | sed 's/Deployed to:/Deployed Forwarder to:/' | tee deployment.txt; \
			forge create ./src/GenericTokenMeta.sol:GenericTokenMeta $${EXTRA_ARGS} --rpc-url $${BTP_RPC_URL} --interactive --constructor-args "GenericTokenMeta" "GTM" "$$(grep "Deployed Forwarder to:" deployment.txt | awk '{print $$4}')" | sed 's/Deployed to:/Deployed GenericTokenMeta to:/' | tee -a deployment.txt; \
		else \
			forge create ./src/Forwarder.sol:Forwarder $${EXTRA_ARGS} --rpc-url $${BTP_RPC_URL} --interactive --gas-price $${BTP_GAS_PRICE} | sed 's/Deployed to:/Deployed Forwarder to:/' | tee deployment.txt; \
			forge create ./src/GenericTokenMeta.sol:GenericTokenMeta $${EXTRA_ARGS} --rpc-url $${BTP_RPC_URL} --interactive --gas-price $${BTP_GAS_PRICE} --constructor-args "GenericTokenMeta" "GTM" "$$(grep "Deployed Forwarder to:" deployment.txt | awk '{print $$4}')" | sed 's/Deployed to:/Deployed GenericTokenMeta to:/' | tee -a deployment.txt; \
		fi; \
	else \
		if [ -z "$${BTP_GAS_PRICE}" ]; then \
			forge create ./src/Forwarder.sol:Forwarder $${EXTRA_ARGS} --rpc-url $${BTP_RPC_URL} --unlocked --from $${BTP_FROM} | sed 's/Deployed to:/Deployed Forwarder to:/' | tee deployment.txt; \
			forge create ./src/GenericTokenMeta.sol:GenericTokenMeta $${EXTRA_ARGS} --rpc-url $${BTP_RPC_URL} --unlocked --from $${BTP_FROM} --constructor-args "GenericTokenMeta" "GTM" "$$(grep "Deployed Forwarder to:" deployment.txt | awk '{print $$4}')" | sed 's/Deployed to:/Deployed GenericTokenMeta to:/' | tee -a deployment.txt; \
		else \
			forge create ./src/Forwarder.sol:Forwarder $${EXTRA_ARGS} --rpc-url $${BTP_RPC_URL} --unlocked --from $${BTP_FROM} --gas-price $${BTP_GAS_PRICE} | sed 's/Deployed to:/Deployed Forwarder to:/' | tee deployment.txt; \
			forge create ./src/GenericTokenMeta.sol:GenericTokenMeta $${EXTRA_ARGS} --rpc-url $${BTP_RPC_URL} --unlocked --from $${BTP_FROM} --gas-price $${BTP_GAS_PRICE} --constructor-args "GenericTokenMeta" "GTM" "$$(grep "Deployed Forwarder to:" deployment.txt | awk '{print $$4}')" | sed 's/Deployed to:/Deployed GenericTokenMeta to:/' | tee -a deployment.txt; \
		fi; \
	fi

cast:
	@echo "Interacting with EVM via Cast..."
	@cast $(SUBCOMMAND)

subgraph:
	@echo "Deploying the subgraph..."
	@rm -Rf subgraph/subgraph.config.json
	@FORWARDER_ADDRESS=$$(grep "Deployed Forwarder to:" deployment.txt | awk '{print $$4}') GENERIC_TOKEN_META_ADDRESS=$$(grep "Deployed GenericTokenMeta to:" deployment.txt | awk '{print $$4}') yq e -p=json -o=json '.datasources[0].address = strenv(GENERIC_TOKEN_META_ADDRESS) | .datasources[1].address = strenv(FORWARDER_ADDRESS) | .chain = env(BTP_NODE_UNIQUE_NAME)' subgraph/subgraph.config.template.json > subgraph/subgraph.config.json
	@cd subgraph && npx graph-compiler --config subgraph.config.json --include node_modules/@openzeppelin/subgraphs/src/datasources ./datasources --export-schema --export-subgraph
	@cd subgraph && yq e '.specVersion = "0.0.4"' -i generated/solidity-token-erc20-metatx.subgraph.yaml
	@cd subgraph && yq e '.description = "Solidity Token ERC20 Meta Tx"' -i generated/solidity-token-erc20-metatx.subgraph.yaml
	@cd subgraph && yq e '.repository = "https://github.com/settlemint/solidity-token-erc20-metatx"' -i generated/solidity-token-erc20-metatx.subgraph.yaml
	@cd subgraph && yq e '.features = ["nonFatalErrors", "fullTextSearch", "ipfsOnEthereumContracts"]' -i generated/solidity-token-erc20-metatx.subgraph.yaml
	@cd subgraph && npx graph codegen generated/solidity-token-erc20-metatx.subgraph.yaml
	@cd subgraph && npx graph build generated/solidity-token-erc20-metatx.subgraph.yaml
	@eval $$(curl -H "x-auth-token: $${BTP_SERVICE_TOKEN}" -s $${BTP_CLUSTER_MANAGER_URL}/ide/foundry/$${BTP_SCS_ID}/env | sed 's/^/export /'); \
	if [ "$${BTP_MIDDLEWARE}" == "" ]; then \
		echo "You have not launched a graph middleware for this smart contract set, aborting..."; \
		exit 1; \
	else \
		cd subgraph; \
		npx graph create --node $${BTP_MIDDLEWARE} $${BTP_SCS_NAME}; \
		npx graph deploy --version-label v1.0.$$(date +%s) --node $${BTP_MIDDLEWARE} --ipfs $${BTP_IPFS}/api/v0 $${BTP_SCS_NAME} generated/solidity-token-erc20-metatx.subgraph.yaml; \
	fi

help:
	@echo "Forge help..."
	@forge --help
	@echo "Anvil help..."
	@anvil --help
	@echo "Cast help..."
	@cast --help
