// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// UpkeepIDConsumerExample.sol imports functions from both ./AutomationRegistryInterface2_0.sol and
// ./interfaces/LinkTokenInterface.sol

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    bytes checkData;
    bytes offchainConfig;
    uint96 amount;
}

interface KeeperRegistrarInterface {
    function registerUpkeep(
        RegistrationParams calldata requestParams
    ) external returns (uint256);
}

contract UpkeepIDConsumerExample {
    LinkTokenInterface public immutable i_link;
    KeeperRegistrarInterface public immutable i_registrar;
    uint public _upKeepId;

    constructor(LinkTokenInterface link, KeeperRegistrarInterface registrar) {
        i_link = link;
        i_registrar = registrar;
    }

    function registerAndPredictID(
        string memory name,
        bytes memory encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes memory checkData,
        bytes memory offchainConfig,
        uint96 amount
    ) public returns (uint256) {
        // LINK must be approved for transfer - this can be done every time or once
        // with an infinite approval
        RegistrationParams memory params = RegistrationParams({
            name: name,
            encryptedEmail: encryptedEmail,
            upkeepContract: upkeepContract,
            gasLimit: gasLimit,
            adminAddress: adminAddress,
            checkData: checkData,
            offchainConfig: offchainConfig,
            amount: amount
        });

        i_link.approve(address(i_registrar), params.amount);
        uint256 upkeepID = i_registrar.registerUpkeep(params);
        if (upkeepID != 0) {
            // DEV - Use the upkeepID however you see fit
            _upKeepId = upkeepID;
            return upkeepID;
        } else {
            revert("auto-approve disabled");
        }
    }
}
