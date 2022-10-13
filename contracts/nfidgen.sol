// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library NFIDGeneration{
    function generateNFID(string memory x, string memory y) public pure returns (uint8[32] memory){
        uint8[32] memory hash_bytes;
        uint8[32] memory hash_bytes_reversed;
        uint8[32] memory hash_bytes_halves_swapped;
        uint8 temp;

        string memory message = string.concat(x, y);
        bytes32 hash_output = sha256(abi.encodePacked(message));

        for (uint i = 0; i < 32; i++) {
            // Stage 1 - original hash bytelist
            hash_bytes[i] = uint8(hash_output[i]);
            // Stage 2 - original reversed
            hash_bytes_reversed[31-i] = uint8(hash_output[i]);
        }

        // Stage 3 - rearranged original
        for (uint i = 0; i < 16; i++) {
            hash_bytes_halves_swapped[i] = hash_bytes[i+16];
            hash_bytes_halves_swapped[i+16] = hash_bytes[i];
        }

        // Stage 4 - reversed rearranged
        for (uint i = 0; i < 16; i++) {
            temp = hash_bytes_halves_swapped[i];
            hash_bytes_halves_swapped[i] = hash_bytes_halves_swapped[31-i];
            hash_bytes_halves_swapped[31-i] = temp;
        }
        
        return hash_bytes_halves_swapped;
    }
}