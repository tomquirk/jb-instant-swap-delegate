pragma solidity ^0.8.16;

import "forge-std/Test.sol";

import {JBPaySplitDelegate} from "../src/JBPaySplitDelegate.sol";
import {IJBDirectory} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import {IJBProjects} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import {IJBPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol";
import {JBCurrencies} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBCurrencies.sol";
import {JBTokenAmount} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBTokenAmount.sol";
import {JBDidPayData} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBDidPayData.sol";
import {JBTokens} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
// import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "../src/interfaces/IWETH9.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract JBPaySplitDelegateTest_Unit is Test {
    uint256 testNumber;
    address mockJBDirectory = address(bytes20(keccak256("mockJBDirectory")));
    address mockJBProjects = address(bytes20(keccak256("mockJBProjects")));
    address mockOwner = address(bytes20(keccak256("mockOwner")));
    address mockTerminalAddress =
        address(bytes20(keccak256("mockTerminalAddress")));
    uint256 projectId = 69;
    IERC20 usdt = new ERC20("USDT", "USDT"); // TODO CHECK goerli USDT 0xba949813b44b2f1e07f25f1befbbd31027cc60af
    IWETH9 weth = IWETH9(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
    IUniswapV3Pool pool =
        IUniswapV3Pool(0xBfcE6397b5A97C91447A8c641ab61Ed965463b32); // USDT<=>WETH

    function setUp() public {
        vm.label(mockTerminalAddress, "mockTerminalAddress");
    }

    function test_ProjectId() public {
        JBPaySplitDelegate _JBPaySplitDelegate = new JBPaySplitDelegate(weth);
        _JBPaySplitDelegate.initialize(
            projectId,
            IJBDirectory(mockJBDirectory),
            pool,
            100_000 // 10%
        );

        assertEq(_JBPaySplitDelegate.projectId(), projectId);
    }

    function test_didPayReverts(address _terminal) public {
        JBPaySplitDelegate _JBPaySplitDelegate = new JBPaySplitDelegate(weth);
        _JBPaySplitDelegate.initialize(
            projectId,
            IJBDirectory(mockJBDirectory),
            pool,
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
            abi.encodeWithSelector(
                JBPaySplitDelegate.INVALID_PAYMENT_EVENT.selector
            )
        );
        _JBPaySplitDelegate.didPay(
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

        // assertEq(_JBPaySplitDelegate.didPay{value: 1}(), false);
    }

    // forwards entire delegated amount to owner
    function test_didPay_paysOwner() public {
        JBPaySplitDelegate _JBPaySplitDelegate = new JBPaySplitDelegate(weth);
        _JBPaySplitDelegate.initialize(
            projectId,
            IJBDirectory(mockJBDirectory),
            pool,
            100_000 // 10%
        );

        // Mock the isTerminalOf call
        vm.mockCall(
            mockJBDirectory,
            abi.encodeWithSelector(
                IJBDirectory.isTerminalOf.selector,
                projectId,
                mockTerminalAddress
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
        vm.mockCall(
            address(weth),
            abi.encodeWithSelector(IWETH9.deposit.selector),
            abi.encode(true) // TODO idk?
        );
        int256 mock0Amount = -1;
        int256 mock1Amount = 10;
        vm.mockCall(
            address(pool),
            abi.encodeWithSelector(IUniswapV3PoolActions.swap.selector),
            abi.encode(mock0Amount, mock1Amount) // TODO idk?
        );

        // The caller is the _expectedCaller however the terminal in the calldata is not correct
        vm.prank(mockTerminalAddress);
        vm.deal(mockTerminalAddress, 100 ether);
        uint256 _initialBalance = address(this).balance;
        uint256 payAmount = 10 ether;
        uint256 delegateAmount = 1 ether;

        _JBPaySplitDelegate.didPay{value: delegateAmount}(
            JBDidPayData(
                msg.sender,
                projectId,
                0,
                JBTokenAmount(JBTokens.ETH, payAmount, 18, JBCurrencies.ETH),
                JBTokenAmount(
                    JBTokens.ETH,
                    delegateAmount,
                    18,
                    JBCurrencies.ETH
                ),
                0,
                msg.sender,
                false,
                "",
                new bytes(0)
            )
        );
    }
}
