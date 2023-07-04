pragma solidity ^0.8.16;

// import "forge-std/Test.sol";

// import {YoloDelegate} from "../src/YoloDelegate.sol";
// import {YoloDelegateDeployer} from "../src/YoloDelegateDeployer.sol";
// import {IJBDirectory} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
// import {IJBPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol";
// import {JBCurrencies} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBCurrencies.sol";
// import {JBTokenAmount} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBTokenAmount.sol";
// import {JBDidPayData} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBDidPayData.sol";
// import {JBTokens} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol";
// import {IJBDelegatesRegistry} from "@jbx-protocol/juice-delegates-registry/src/interfaces/IJBDelegatesRegistry.sol";
// import {JBDelegatesRegistry} from "@jbx-protocol/juice-delegates-registry/src/JBDelegatesRegistry.sol";

// contract YoloDelegateDeployerTest_Unit is Test {
//     address mockRegistry = address(bytes20(keccak256("mockRegistry")));
//     address mockJBDirectory = address(bytes20(keccak256("mockJBDirectory")));

//     uint256 mockProjectId = 69;

//     function setUp() public {}

//     function test_deployDelegateFor() public {
//         YoloDelegate _delegateImplementation = new YoloDelegate();
//         JBDelegatesRegistry delegatesRegistry = new JBDelegatesRegistry();

//         YoloDelegateDeployer _yoloDelegateDeployer = new YoloDelegateDeployer(
//             _delegateImplementation,
//             delegatesRegistry
//         );
//         _yoloDelegateDeployer.deployDelegateFor(
//             mockProjectId,
//             IJBDirectory(mockJBDirectory)
//         );
//     }
// }
