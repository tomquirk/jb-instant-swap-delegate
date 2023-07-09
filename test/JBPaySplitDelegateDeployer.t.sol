pragma solidity ^0.8.16;

// import "forge-std/Test.sol";

// import {JBPaySplitDelegate} from "../src/JBPaySplitDelegate.sol";
// import {JBPaySplitDelegateDeployer} from "../src/JBPaySplitDelegateDeployer.sol";
// import {IJBDirectory} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
// import {IJBPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol";
// import {JBCurrencies} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBCurrencies.sol";
// import {JBTokenAmount} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBTokenAmount.sol";
// import {JBDidPayData} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBDidPayData.sol";
// import {JBTokens} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol";
// import {IJBDelegatesRegistry} from "@jbx-protocol/juice-delegates-registry/src/interfaces/IJBDelegatesRegistry.sol";
// import {JBDelegatesRegistry} from "@jbx-protocol/juice-delegates-registry/src/JBDelegatesRegistry.sol";

// contract JBPaySplitDelegateDeployerTest_Unit is Test {
//     address mockRegistry = address(bytes20(keccak256("mockRegistry")));
//     address mockJBDirectory = address(bytes20(keccak256("mockJBDirectory")));

//     uint256 mockProjectId = 69;

//     function setUp() public {}

//     function test_deployDelegateFor() public {
//         JBPaySplitDelegate _delegateImplementation = new JBPaySplitDelegate();
//         JBDelegatesRegistry delegatesRegistry = new JBDelegatesRegistry();

//         JBPaySplitDelegateDeployer _JBPaySplitDelegateDeployer = new JBPaySplitDelegateDeployer(
//             _delegateImplementation,
//             delegatesRegistry
//         );
//         _JBPaySplitDelegateDeployer.deployDelegateFor(
//             mockProjectId,
//             IJBDirectory(mockJBDirectory)
//         );
//     }
// }
