// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


library tokenUtils {
    function getTokenMetadata(IERC20 token) external view  returns (uint8 decimals, string memory symbol) {
        IERC20Metadata metadataToken = IERC20Metadata(address(token));
        decimals = metadataToken.decimals();
        symbol = metadataToken.symbol();
    }
}
