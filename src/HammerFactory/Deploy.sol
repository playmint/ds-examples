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
        // find the base item ids we will use as inputs for our hammer factory
        bytes24 none = 0x0;
        bytes24 glassGreenGoo = ItemUtils.GlassGreenGoo();
        bytes24 beakerBlueGoo = ItemUtils.BeakerBlueGoo();
        bytes24 flaskRedGoo = ItemUtils.FlaskRedGoo();

        bytes24 hammer = ItemUtils.register(
            ds,
            ItemConfig({
                id: nameToId("hammer"),
                name: "Hammer",
                icon: "15-38",
                greenGoo: 10, //In combat, Green Goo increases life
                blueGoo: 0, //In combat, Blue Goo increases defense
                redGoo: 6, //In combat, Red Goo increases attack
                stackable: false,
                implementation: address(0),
                plugin: ""
            })
        );

        // register a new building kind
        BuildingUtils.register(
            ds,
            BuildingConfig({
                id: nameToId("hammer-factory"),
                name: "Hammer Factory",
                materials: [
                    Material({quantity: 10, item: glassGreenGoo}), // these are what it costs to construct the factory
                    Material({quantity: 10, item: beakerBlueGoo}),
                    Material({quantity: 10, item: flaskRedGoo}),
                    Material({quantity: 0, item: none})
                ],
                inputs: [
                    Input({quantity: 20, item: glassGreenGoo}), // these are required inputs to get the output
                    Input({quantity: 12, item: flaskRedGoo}),
                    Input({quantity: 0, item: none}),
                    Input({quantity: 0, item: none})
                ],
                outputs: [
                    Output({quantity: 1, item: hammer}) // this is the output that can be crafted given the inputs
                ],
                implementation: address(new ExampleBuildingKind()),
                plugin: vm.readFile("./src/HammerFactory/BuildingKind.js")
            })
        );
    }

    function nameToId(string memory name) private returns (uint64) {
        return uint64(uint256(keccak256(abi.encodePacked("example", name))));
    }

}
