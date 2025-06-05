// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface ICurationValidator {
    function isApprovedCollection(
        address tokenContract
    ) external view returns (bool);
}
