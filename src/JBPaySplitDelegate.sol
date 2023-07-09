// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// import {mulDiv} from '@prb/math/src/Common.sol';
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IJBDirectory} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import {IJBProjects} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import {IJBFundingCycleDataSource} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleDataSource.sol";
import {IJBPayDelegate} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayDelegate.sol";
import {IJBPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol";
import {IJBRedemptionDelegate} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBRedemptionDelegate.sol";
import {JBPayParamsData} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBPayParamsData.sol";
import {JBDidPayData} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBDidPayData.sol";
import {JBTokens} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol";
import {JBDidRedeemData} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBDidRedeemData.sol";
import {JBRedeemParamsData} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBRedeemParamsData.sol";
import {JBPayDelegateAllocation} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBPayDelegateAllocation.sol";
import {JBRedemptionDelegateAllocation} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBRedemptionDelegateAllocation.sol";
import "@paulrberg/contracts/math/PRBMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
// Import the Uniswap V3 interfaces
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./interfaces/IWETH9.sol";

/// @notice A contract that is a Data Source, a Pay Delegate, and a Redemption Delegate.
/// @dev This example implementation confines payments to an allow list.
contract JBPaySplitDelegate is
    IJBFundingCycleDataSource,
    IJBPayDelegate,
    IUniswapV3SwapCallback
{
    error INVALID_PAYMENT_EVENT();
    error INVALID_POOL();
    error UNAUTHORIZED();

    /// @dev from uniswap TickMath
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    /// @notice the maximum value for percentSwap.
    uint256 public constant MAX_PERCENT_SWAP = 1_000_000_000;

    /// @notice The WETH contract
    IWETH9 public immutable weth;

    /// @notice The Juicebox project ID this contract's functionality applies to.
    uint256 public projectId;

    /// @notice The directory of terminals and controllers for projects.
    IJBDirectory public directory;

    /// @notice The uniswap pool where token1 is the target token.
    IUniswapV3Pool public pool;

    /// @notice the percent of the payment to swap to the token
    uint256 public percentSwap;

    /// @notice The Uniswap V3 pool callback
    function uniswapV3SwapCallback(
        int256 amount0Delta, // weth
        int256 amount1Delta, // token (not used)
        bytes calldata data // token (not used)
    ) external override {
        // Check if this is really a callback
        if (msg.sender != address(pool)) revert UNAUTHORIZED();

        // Assign 0 and 1 accordingly
        uint256 _amountToSend = uint256(amount0Delta);

        // Wrap the eth (=> weth)
        weth.deposit{value: _amountToSend}();

        // Transfer the weth to the pool.
        weth.transfer(address(pool), _amountToSend);
    }

    /// @notice This function gets called when the project receives a payment.
    /// @dev Part of IJBFundingCycleDataSource.
    /// @dev This implementation just sets this contract up to receive a `didPay` call.
    /// @param _data The Juicebox standard project payment data. See https://docs.juicebox.money/dev/api/data-structures/jbpayparamsdata/.
    /// @return weight The weight that project tokens should get minted relative to. This is useful for optionally customizing how many tokens are issued per payment.
    /// @return memo A memo to be forwarded to the event. Useful for describing any new actions that are being taken.
    /// @return delegateAllocations Amount to be sent to delegates instead of adding to local balance. Useful for auto-routing funds from a treasury as payment come in.
    function payParams(
        JBPayParamsData calldata _data
    )
        external
        view
        virtual
        override
        returns (
            uint256 weight,
            string memory memo,
            JBPayDelegateAllocation[] memory delegateAllocations
        )
    {
        // Forward the default weight received from the protocol.
        weight = _data.weight;
        // Forward the default memo received from the payer.
        memo = _data.memo;
        // Add `this` contract as a Pay Delegate so that it receives a `didPay` call.
        // Send a portion of funds to the delegate (keep most of the funds in the treasury).
        delegateAllocations = new JBPayDelegateAllocation[](1);
        delegateAllocations[0] = JBPayDelegateAllocation(
            this,
            PRBMath.mulDiv(_data.amount.value, percentSwap, MAX_PERCENT_SWAP)
        );
    }

    function redeemParams(
        JBRedeemParamsData calldata _data
    )
        external
        view
        virtual
        override
        returns (
            uint256 reclaimAmount,
            string memory memo,
            JBRedemptionDelegateAllocation[] memory delegateAllocations
        )
    {}

    constructor(IWETH9 _weth) {
        weth = _weth;
    }

    /// @notice Initializes the clone contract with project details and a directory from which ecosystem payment terminals and controller can be found.
    /// @param _projectId The ID of the project this contract's functionality applies to.
    /// @param _directory The directory of terminals and controllers for projects.
    function initialize(
        uint256 _projectId,
        IJBDirectory _directory,
        IUniswapV3Pool _pool,
        uint256 _percentSwap
    ) external {
        // Stop re-initialization.
        if (projectId != 0) revert();
        if (_pool.token0() != address(weth)) revert INVALID_POOL();

        projectId = _projectId;
        directory = _directory;
        pool = _pool;
        percentSwap = _percentSwap;
    }

    /// @notice Received hook from the payment terminal after a payment. Swaps the delegated ETH for token1 of the contract's pool.
    /// @dev Reverts if the calling contract is not one of the project's terminals.
    /// @param _data Standard Juicebox project payment data. See https://docs.juicebox.money/dev/api/data-structures/jbdidpaydata/.
    function didPay(
        JBDidPayData calldata _data
    ) external payable virtual override {
        // Make sure the caller is a terminal of the project, and that the call is being made on behalf of an interaction with the correct project.
        if (
            !directory.isTerminalOf(
                projectId,
                IJBPaymentTerminal(msg.sender)
            ) || _data.projectId != projectId
        ) revert INVALID_PAYMENT_EVENT();

        uint256 ethAmount = _data.forwardedAmount.value;

        // Perform the swap
        pool.swap(
            address(this),
            true,
            int256(ethAmount),
            MIN_SQRT_RATIO + 1,
            ""
        );
        // NOTE at this point, uniswapV3SwapCallback will be called.
        // Code below will execute after uniswapV3SwapCallback.

        IJBProjects jbProjects = directory.projects();
        address payable projectOwner = payable(jbProjects.ownerOf(projectId));

        IERC20 token = IERC20(pool.token1());
        // Transfer the purchased tokens to the caller
        token.transfer(projectOwner, token.balanceOf(address(this)));

        _data;
    }

    function setPool(IUniswapV3Pool _pool) external {
        IJBProjects jbProjects = directory.projects();

        if (msg.sender != jbProjects.ownerOf(projectId)) revert UNAUTHORIZED();
        if (_pool.token0() != address(weth)) revert INVALID_POOL();

        pool = _pool;
    }

    /// @notice Indicates if this contract adheres to the specified interface.
    /// @dev See {IERC165-supportsInterface}.
    /// @param _interfaceId The ID of the interface to check for adherence to.
    /// @return A flag indicating if the provided interface ID is supported.
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override returns (bool) {
        return
            _interfaceId == type(IJBFundingCycleDataSource).interfaceId ||
            _interfaceId == type(IJBPayDelegate).interfaceId;
    }
}
