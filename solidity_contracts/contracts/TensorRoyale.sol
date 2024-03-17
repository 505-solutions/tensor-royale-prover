// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract TensorRoyale {
    struct RequestKey {
        uint256 requestId;
        uint256 publicKey;
        uint256 requestCommitment;
    }

    mapping(uint256 => RequestKey) public requestKeys;
    mapping(uint256 => mapping(address => uint256)) public payments;

    address usdcAddress;
    function setUsdcAddress(address _usdcAddress) external {
        usdcAddress = _usdcAddress;
    }

    function registerRequest(
        uint256 publicKey,
        uint256 requestId,
        uint256 requestCommitment,
        uint256 usdcPayment
    ) external {
        require(publicKey < 2 ** 251 + 17 * 2 ** 192 + 1, "Invalid stark Key");
        require(publicKey > 0, "Invalid stark Key");

        requestKeys[requestId] = RequestKey({
            publicKey: publicKey,
            requestId: requestId,
            requestCommitment: requestCommitment
        });

        if (usdcPayment == 0) {
            return;
        }

        IERC20(usdcAddress).transferFrom(
            msg.sender,
            address(this),
            usdcPayment
        );

        payments[requestId][msg.sender] = usdcPayment;
    }

    function transitionState(uint256[] calldata programOutput) external {
        for (uint256 i = 0; i < programOutput.length; i += 3) {
            uint256 requestId = programOutput[i];
            uint256 publicKey = programOutput[i + 1];
            uint256 requestCommitment = programOutput[i + 2];

            require(
                requestKeys[requestId].requestId == requestId,
                "Invalid request id"
            );
            require(
                requestKeys[requestId].publicKey == publicKey,
                "Invalid public key"
            );
            require(
                requestKeys[requestId].requestCommitment == requestCommitment,
                "Invalid request commitment"
            );

            delete requestKeys[requestId];
        }
    }
}
