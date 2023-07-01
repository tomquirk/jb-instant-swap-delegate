// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IJBDelegatesRegistry} from "@jbx-protocol/juice-delegates-registry/src/interfaces/IJBDelegatesRegistry.sol";
import {IJBDirectory} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import {YoloDelegate} from "./YoloDelegate.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
// import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
// import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "./interfaces/IWETH9.sol";

/// @notice A contract that deploys a delegate contract.
contract YoloDelegateDeployer {
    event DelegateDeployed(
        uint256 projectId,
        YoloDelegate delegate,
        IJBDirectory directory,
        address caller
    );

    /// @notice This contract's current nonce, used for the Juicebox delegates registry.
    uint256 internal _nonce;

    /// @notice An implementation of the Delegate being deployed.
    YoloDelegate public immutable delegateImplementation;

    /// @notice A contract that stores references to deployer contracts of delegates.
    IJBDelegatesRegistry public immutable delegatesRegistry;

    /// @param _delegateImplementation The delegate implementation that will be cloned.
    /// @param _delegatesRegistry A contract that stores references to delegate deployer contracts.
    constructor(
        YoloDelegate _delegateImplementation,
        IJBDelegatesRegistry _delegatesRegistry
    ) {
        delegateImplementation = _delegateImplementation;
        delegatesRegistry = _delegatesRegistry;
    }

    /// @notice Deploys a delegate for the provided project.
    /// @param _projectId The ID of the project for which the delegate will be deployed.
    /// @param _directory The directory of terminals and controllers for projects.
    /// @return delegate The address of the newly deployed delegate.
    function deployDelegateFor(
        uint256 _projectId,
        IJBDirectory _directory,
        IERC20 _token,
        IWETH9 _weth,
        // IUniswapV3Pool _pool,
        uint256 _percentSwap
    ) external returns (YoloDelegate delegate) {
        // Deploy the delegate clone from the implementation.
        delegate = YoloDelegate(Clones.clone(address(delegateImplementation)));

        // Initialize it.
        delegate.initialize(
            _projectId,
            _directory,
            _token,
            _weth,
            // IUniswapV3Pool _pool,
            _percentSwap
        );

        // Add the delegate to the registry. Contract nonce starts at 1.
        // delegatesRegistry.addDelegate(address(this), ++_nonce);

        emit DelegateDeployed(_projectId, delegate, _directory, msg.sender);
    }
}
