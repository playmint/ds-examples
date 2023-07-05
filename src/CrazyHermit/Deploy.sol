// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {Game} from "@ds/Game.sol";
import {Actions} from "@ds/actions/Actions.sol";
import {Node, Schema, State} from "@ds/schema/Schema.sol";
import {ItemUtils, ItemConfig} from "@ds/utils/ItemUtils.sol";
import {BuildingUtils, BuildingConfig, Material, Input, Output} from "@ds/utils/BuildingUtils.sol";
import {CrazyHermit} from "./CrazyHermit.sol";

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
        // deploy the new item and building
        bytes24 newItem = registerItem();
        bytes24 building = registerBuilding(newItem);

        // dump deployed ids
        console2.log("ItemKind", uint256(bytes32(newItem)));
        console2.log("BuildingKind", uint256(bytes32(building)));
    }

    // register a new item id
    function registerItem() private returns (bytes24 itemKind) {
        return ItemUtils.register(ds, ItemConfig({
            id: nameToId("dismembered-hand"),
            name: "Dismembered Hand",
            icon: "01-140",
            greenGoo: 100,
            blueGoo: 0,
            redGoo: 0,
            stackable: false,
            implementation: address(0),
            plugin: ""
        }));
    }

    // register the new building
    function registerBuilding(bytes24 newItem) private returns (bytes24 buildingKind) {

        // find the base item ids we will use as inputs
        bytes24 none = 0x0;
        bytes24 glassGreen = ItemUtils.GlassGreenGoo();
        bytes24 vibrantGreen = 0x6a7a67f00000006500000001000000140000000000000000;
        bytes24 reallyGreen = 0x6a7a67f00000006600000001000000c80000000000000000;


        return BuildingUtils.register(ds, BuildingConfig({
            id: nameToId("crazy-hermit"),
            name: "Crazy Hermit",
            materials: [
                Material({quantity: 10, item: glassGreen}), // these are what it costs to construct the factory
                Material({quantity: 10, item: ItemUtils.FlaskRedGoo()}),
                Material({quantity: 10, item: ItemUtils.BeakerBlueGoo()}),
                Material({quantity: 0, item: none})
            ],
            inputs: [
                Input({quantity: 1, item: glassGreen}), // these are required inputs to get the outpu
                Input({quantity: 1, item: vibrantGreen}),
                Input({quantity: 1, item: reallyGreen}),
                Input({quantity: 0, item: none})
            ],
            outputs: [
                Output({quantity: 1, item: newItem}) // this is the output that can be crafted given the inputs
            ],
            implementation: address(new CrazyHermit()),
            plugin: vm.readFile("./src/CrazyHermit/CrazyHermit.js")
        }));
    }

    function nameToId(string memory name) private pure returns (uint64) {
        return uint64(uint256(keccak256(abi.encodePacked("example", name))));
    }
}
