// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";

contract GenNFID {
    function generateNFID(string memory x, string memory y)
        public
        pure
        returns (uint256)
    {
        uint8[32] memory hash_bytes;
        uint8[32] memory hash_bytes_reversed;
        uint8[32] memory hash_bytes_halves_swapped;
        uint8 temp;
        string memory hash_str;

        string memory message = string.concat(x, y);
        bytes32 hash_output = sha256(abi.encodePacked(message));

        for (uint256 i = 0; i < 32; i++) {
            // Stage 1 - original hash bytelist
            hash_bytes[i] = uint8(hash_output[i]);
            // Stage 2 - original reversed
            hash_bytes_reversed[31 - i] = uint8(hash_output[i]);
        }

        // Stage 3 - rearranged original
        for (uint256 i = 0; i < 16; i++) {
            hash_bytes_halves_swapped[i] = hash_bytes[i + 16];
            hash_bytes_halves_swapped[i + 16] = hash_bytes[i];
        }

        // Stage 4 - reversed rearranged
        for (uint256 i = 0; i < 16; i++) {
            temp = hash_bytes_halves_swapped[i];
            hash_bytes_halves_swapped[i] = hash_bytes_halves_swapped[31 - i];
            hash_bytes_halves_swapped[31 - i] = temp;
        }

        for (uint256 i = 0; i < 32; i++) {
            hash_str = string.concat(hash_str, Strings.toString(hash_bytes_halves_swapped[i]));
        }

        bytes memory a = new bytes(16 - 1 + 1);
        for (uint256 i = 0; i <= 16 - 1; i++) {
            a[i] = bytes(hash_str)[i + 1 - 1];
        }

        uint256 result = 0;
        for (uint256 i = 0; i < a.length; i++) {
            uint256 c = uint256(uint8(a[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
        return result;
    }
}

//generates 16 digit nfid 