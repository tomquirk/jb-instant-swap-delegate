// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {IJBDelegatesRegistry} from "@jbx-protocol/juice-delegates-registry/src/interfaces/IJBDelegatesRegistry.sol";
import {IJBOperatorStore} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBOperatorStore.sol";
import {JBPaySplitDelegate} from "./../src/JBPaySplitDelegate.sol";
import {JBPaySplitDelegateDeployer} from "./../src/JBPaySplitDelegateDeployer.sol";
import "../src/interfaces/IWETH9.sol";

abstract contract Deploy is Script {
    function _run(IJBDelegatesRegistry _registry) internal {
        vm.startBroadcast();
        JBPaySplitDelegate _delegateImplementation = new JBPaySplitDelegate(
            IWETH9(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6) // weth
        );
        new JBPaySplitDelegateDeployer(_delegateImplementation, _registry);
        vm.stopBroadcast();
    }
}

contract DeployMainnet is Deploy {
    IJBDelegatesRegistry _registry =
        IJBDelegatesRegistry(0x7A53cAA1dC4d752CAD283d039501c0Ee45719FaC);

    function run() public {
        _run(_registry);
    }
}

contract DeployGoerli is Deploy {
    IJBDelegatesRegistry _registry =
        IJBDelegatesRegistry(0xCe3Ebe8A7339D1f7703bAF363d26cD2b15D23C23);

    function run() public {
        _run(_registry);
    }
}
