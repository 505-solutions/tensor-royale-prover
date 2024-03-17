// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract TensorRoyale {
    struct RequestKey {
        uint256 requestId;
        uint256 publicKey;
        uint256 requestCommitment;
    }

    mapping(uint256 => RequestKey) public requestKeys;
    mapping(address => uint256) public requestCommitments;

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
    }

    function transitionState(
        uint256[] calldata programOutput
    ) external view returns (RequestKey memory) {
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
        }
    }
}
