// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {Game} from "@ds/Game.sol";
import {Actions} from "@ds/actions/Actions.sol";
import {Node, Schema, State} from "@ds/schema/Schema.sol";
import {ItemUtils, ItemConfig} from "@ds/utils/ItemUtils.sol";
import {BuildingUtils, BuildingConfig, Material, Input, Output} from "@ds/utils/BuildingUtils.sol";
import {RecruitmentOffice} from "./RecruitmentOffice.sol";

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
        bytes24 item = registerItem();
        bytes24 building = registerBuilding(item);

        // dump deployed ids
        console2.log("ItemKind", uint256(bytes32(item)));
        console2.log("BuildingKind", uint256(bytes32(building)));
    }


    // register a new item id
    function registerItem() private returns (bytes24 itemKind) {
        return ItemUtils.register(
            ds,
            ItemConfig({
                id: nameToId("badge-of-allegiance"),
                name: "Badge of Allegiance",
                icon: "15-127",
                greenGoo: 0, //In combat, Green Goo increases life
                blueGoo: 100, //In combat, Blue Goo increases defense
                redGoo: 0, //In combat, Red Goo increases attack
                stackable: false,
                implementation: address(0),
                plugin: ""
            })
        );
    }


    // register a new
    function registerBuilding(bytes24 thisItem) private returns (bytes24 buildingKind) {
        // find the base item ids we will use as inputs for our hammer factory
        bytes24 none = 0x0;

        // register a new building kind
        return BuildingUtils.register(
            ds,
            BuildingConfig({
                id: nameToId("recruitment-office"),
                name: "Recruitment Office",
                materials: [
                    Material({quantity: 10, item: ItemUtils.GlassGreenGoo()}), // these are what it costs to construct the factory
                    Material({quantity: 10, item: ItemUtils.BeakerBlueGoo()}),
                    Material({quantity: 10, item: ItemUtils.FlaskRedGoo()}),
                    Material({quantity: 0, item: none})
                ],
                inputs: [
                    Input({quantity: 100, item: ItemUtils.BeakerBlueGoo()}), // these are required inputs to get the output
                    Input({quantity: 0, item: none}),
                    Input({quantity: 0, item: none}),
                    Input({quantity: 0, item: none})
                ],
                outputs: [
                    Output({quantity: 1, item: thisItem}) // this is the output that can be crafted given the inputs
                ],
                implementation: address(new RecruitmentOffice()),
                plugin: vm.readFile("src/RecruitmentOffice/RecruitmentOffice.js")
            })
        );
    }

    function nameToId(string memory name) private pure returns (uint64) {
        return uint64(uint256(keccak256(abi.encodePacked("example", name))));
    }
}
