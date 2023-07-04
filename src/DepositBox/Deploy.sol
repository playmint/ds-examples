// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {Game} from "@ds/Game.sol";
import {Actions} from "@ds/actions/Actions.sol";
import {Node, Schema, State} from "@ds/schema/Schema.sol";
import {ItemUtils, ItemConfig} from "@ds/utils/ItemUtils.sol";
import {BuildingUtils, BuildingConfig, Material, Input, Output} from "@ds/utils/BuildingUtils.sol";
import {ExampleBuildingKind} from "./BuildingKind.sol";

using Schema for State;

contract Deployer is Script {
    uint256 playerPrivateKey;
    Game ds;

    function setUp() public {
        playerPrivateKey = vm.envUint("PLAYER_PRIVATE_KEY");
        ds = Game(vm.envAddress("GAME_ADDRESS"));
    }

    function run() public {
        vm.startBroadcast(playerPrivateKey);
        deploy();
        vm.stopBroadcast();
    }

    function deploy() private {
        bytes24 none = 0x0;
        bytes24 glassGreenGoo = ItemUtils.GlassGreenGoo();
        bytes24 beakerBlueGoo = ItemUtils.BeakerBlueGoo();
        bytes24 flaskRedGoo = ItemUtils.FlaskRedGoo();

        // register a new building kind
        BuildingUtils.register(
            ds,
            BuildingConfig({
                id: nameToId("deposit-box"),
                name: "Saftey Deposit Box",
                materials: [
                    Material({quantity: 100, item: glassGreenGoo}),
                    Material({quantity: 100, item: beakerBlueGoo}),
                    Material({quantity: 100, item: flaskRedGoo}),
                    Material({quantity: 0, item: none})
                ],
                inputs: [
                    Input({quantity: 0, item: none}),
                    Input({quantity: 0, item: none}),
                    Input({quantity: 0, item: none}),
                    Input({quantity: 0, item: none})
                ],
                outputs: [
                    Output({quantity: 0, item: none})
                ],
                implementation: address(new ExampleBuildingKind()),
                plugin: vm.readFile("src/DepositBox/BuildingKind.js")
            })
        );
    }

    function nameToId(string memory name) private pure returns (uint64) {
        return uint64(uint256(keccak256(abi.encodePacked("example", name))));
    }
}
