pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {YoloDelegate} from "../src/YoloDelegate.sol";
import {IJBDirectory} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import {IJBPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol";
import {JBCurrencies} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBCurrencies.sol";
import {JBTokenAmount} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBTokenAmount.sol";
import {JBDidPayData} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBDidPayData.sol";
import {JBTokens} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol";

contract YoloDelegateTest_Unit is Test {
    uint256 testNumber;
    address mockJBDirectory = address(bytes20(keccak256("mockJBDirectory")));
    address mockTerminalAddress =
        address(bytes20(keccak256("mockTerminalAddress")));
    uint256 projectId = 69;

    function setUp() public {
        vm.label(mockTerminalAddress, "mockTerminalAddress");
    }

    function test_ProjectId() public {
        YoloDelegate _yoloDelegate = new YoloDelegate();
        _yoloDelegate.initialize(projectId, IJBDirectory(mockJBDirectory));

        assertEq(_yoloDelegate.projectId(), projectId);
    }

    function test_didPayReverts(address _terminal) public {
        YoloDelegate _yoloDelegate = new YoloDelegate();
        _yoloDelegate.initialize(projectId, IJBDirectory(mockJBDirectory));
        // Mock the directory call
        vm.assume(_terminal != mockTerminalAddress);
        // Mock the directory call
        vm.mockCall(
            mockJBDirectory,
            abi.encodeWithSelector(
                IJBDirectory.isTerminalOf.selector,
                projectId,
                _terminal
            ),
            abi.encode(false)
        );
        // The caller is the _expectedCaller however the terminal in the calldata is not correct
        vm.prank(_terminal);
        vm.expectRevert(
            abi.encodeWithSelector(YoloDelegate.INVALID_PAYMENT_EVENT.selector)
        );
        _yoloDelegate.didPay(
            JBDidPayData(
                msg.sender,
                projectId,
                0,
                JBTokenAmount(address(0), 0, 18, JBCurrencies.ETH),
                JBTokenAmount(address(0), 0, 18, JBCurrencies.ETH), // 0 fwd to delegate
                0,
                msg.sender,
                false,
                "",
                new bytes(0)
            )
        );

        // assertEq(_yoloDelegate.didPay{value: 1}(), false);
    }

    function test_didPay_paysRandomProject() public {
        YoloDelegate _yoloDelegate = new YoloDelegate();
        _yoloDelegate.initialize(projectId, IJBDirectory(mockJBDirectory));
        uint256 mockCandidateProjectId = 42;
        // add a single candidate
        _yoloDelegate.addCandidateProjectId(mockCandidateProjectId);
        address _initialTerminal = address(
            bytes20(keccak256("_initialTerminal"))
        );
        address _candidateTerminal = address(
            bytes20(keccak256("_candidateTerminal"))
        );

        // Mock the isTerminalOf call
        vm.mockCall(
            mockJBDirectory,
            abi.encodeWithSelector(
                IJBDirectory.isTerminalOf.selector,
                projectId,
                _initialTerminal
            ),
            abi.encode(true)
        );

        // Mock the primaryTerminalOf call
        vm.mockCall(
            mockJBDirectory,
            abi.encodeWithSelector(
                IJBDirectory.primaryTerminalOf.selector,
                mockCandidateProjectId,
                JBTokens.ETH
            ),
            abi.encode(_candidateTerminal)
        );

        // // Mock the primaryTerminalOf call
        vm.mockCall(
            _candidateTerminal,
            abi.encodeWithSelector(IJBPaymentTerminal.pay.selector),
            abi.encode()
        );

        // The caller is the _expectedCaller however the terminal in the calldata is not correct
        vm.prank(_initialTerminal);
        vm.deal(_initialTerminal, 100 ether);

        _yoloDelegate.didPay{value: 1}(
            JBDidPayData(
                msg.sender,
                projectId,
                0,
                JBTokenAmount(JBTokens.ETH, 1, 18, JBCurrencies.ETH),
                JBTokenAmount(JBTokens.ETH, 1, 18, JBCurrencies.ETH), // 0 fwd to delegate
                0,
                msg.sender,
                false,
                "",
                new bytes(0)
            )
        );

        vm.expectCall(
            address(_candidateTerminal),
            1,
            abi.encodeCall(
                IJBPaymentTerminal(_candidateTerminal).pay,
                (
                    mockCandidateProjectId,
                    1,
                    JBTokens.ETH,
                    msg.sender,
                    0,
                    false,
                    "",
                    new bytes(0)
                )
            )
        );
    }
}
