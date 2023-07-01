pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {YoloDelegate} from "../src/YoloDelegate.sol";
import {IJBDirectory} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import {IJBProjects} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import {IJBPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol";
import {JBCurrencies} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBCurrencies.sol";
import {JBTokenAmount} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBTokenAmount.sol";
import {JBDidPayData} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBDidPayData.sol";
import {JBTokens} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
// import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
// import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "../src/interfaces/IWETH9.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract YoloDelegateTest_Unit is Test {
    uint256 testNumber;
    address mockJBDirectory = address(bytes20(keccak256("mockJBDirectory")));
    address mockJBProjects = address(bytes20(keccak256("mockJBProjects")));
    address mockOwner = address(bytes20(keccak256("mockOwner")));
    address mockTerminalAddress =
        address(bytes20(keccak256("mockTerminalAddress")));
    uint256 projectId = 69;
    IERC20 usdc = IERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
    IWETH9 weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    function setUp() public {
        vm.label(mockTerminalAddress, "mockTerminalAddress");
    }

    function test_ProjectId() public {
        YoloDelegate _yoloDelegate = new YoloDelegate();
        _yoloDelegate.initialize(
            projectId,
            IJBDirectory(mockJBDirectory),
            usdc,
            weth,
            // IUniswapV3Pool _pool,
            100_000 // 10%
        );

        assertEq(_yoloDelegate.projectId(), projectId);
    }

    function test_didPayReverts(address _terminal) public {
        YoloDelegate _yoloDelegate = new YoloDelegate();
        _yoloDelegate.initialize(
            projectId,
            IJBDirectory(mockJBDirectory),
            usdc,
            weth,
            // IUniswapV3Pool _pool,
            100_000 // 10%
        );
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

    // forwards entire delegated amount to owner
    function test_didPay_paysOwner(address _initialTerminal) public {
        YoloDelegate _yoloDelegate = new YoloDelegate();
        _yoloDelegate.initialize(
            projectId,
            IJBDirectory(mockJBDirectory),
            usdc,
            weth,
            // IUniswapV3Pool _pool,
            100_000 // 10%
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

        vm.mockCall(
            mockJBDirectory,
            abi.encodeWithSelector(IJBDirectory.projects.selector),
            abi.encode(mockJBProjects)
        );
        vm.mockCall(
            mockJBProjects,
            abi.encodeWithSelector(IERC721.ownerOf.selector, projectId),
            abi.encode(mockOwner)
        );

        // The caller is the _expectedCaller however the terminal in the calldata is not correct
        vm.prank(_initialTerminal);
        vm.deal(_initialTerminal, 100 ether);
        uint256 _initialBalance = address(this).balance;

        _yoloDelegate.didPay{value: 10 ether}(
            JBDidPayData(
                msg.sender,
                projectId,
                0,
                JBTokenAmount(JBTokens.ETH, 10 ether, 18, JBCurrencies.ETH),
                JBTokenAmount(JBTokens.ETH, 10 ether, 18, JBCurrencies.ETH), // 0 fwd to delegate
                0,
                msg.sender,
                false,
                "",
                new bytes(0)
            )
        );

        assertNotEq(_initialBalance, mockOwner.balance);
        assertEq(mockOwner.balance, 10 ether);
    }
}
