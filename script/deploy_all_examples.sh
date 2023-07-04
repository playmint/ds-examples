#!/usr/bin/env bash

set -e

export PLAYER_PRIVATE_KEY=${PLAYER_PRIVATE_KEY:-"0x24941b1db84a65ded87773081c700c22f50fe26c8f9d471dc480207d96610ffd"}
export GAME_ADDRESS=${GAME_ADDRESS:-"0x1D8e3A7Dc250633C192AC1bC9D141E1f95C419AB"}

for example in src/*; do
	(cd "${example}" && forge script ./Deploy.sol \
		--broadcast \
		--rpc-url "http://localhost:8545" \
	)
done
