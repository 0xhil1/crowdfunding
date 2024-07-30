// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Errors} from "src/utils/Errors.sol";

contract CrowdFunding is Ownable {
    using SafeERC20 for IERC20;

    constructor(address owner) Ownable(owner) {}
}
