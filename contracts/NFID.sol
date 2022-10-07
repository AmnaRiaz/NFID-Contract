// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";

error ZeroAddress();
error AddressHasAlreadyNFID();
error NFIDAlreadyExists();
error NonExistingNFID();
error AddressHasNoNFID();
error AddressHasNoAssociatedNFID();

contract NFID is Ownable {
    event Mint(address indexed userAddress, uint256 nfid);
    event Burn(address indexed userAddress, address indexed to, uint256 nfid);

    struct NFIDDocument {
        address userAddress;
        uint256 nfid;
    }

    mapping(address => uint256) public nfid_number;
    mapping(uint256 => NFIDDocument) public nfid_document;
    mapping(uint256 => address) public owner;

    function _exists(uint256 nfid) internal view returns (bool) {
        return owner[nfid] != address(0);
    }

    function checkNFID(address userAddress) public view returns (bool) {
        return nfid_number[userAddress] != 0;
    }

    function findNFID(address userAddress) public view returns (uint256) {
        return nfid_number[userAddress];
    }

    function addressAssociatedNFID(address from, uint256 nfid)
        public
        view
        returns (bool)
    {
        return nfid_number[from] == nfid;
    }

    function mint(address userAddress, uint256 nfid)
        public
        onlyOwner
        returns (NFIDDocument memory)
    {
        if (userAddress == address(0)) {
            revert ZeroAddress();
        }
        if (checkNFID(userAddress)) {
            revert AddressHasAlreadyNFID();
        }
        if (_exists(nfid)) {
            revert NFIDAlreadyExists();
        }

        nfid_number[userAddress] = nfid;
        nfid_document[nfid].userAddress = userAddress;
        nfid_document[nfid].nfid = nfid;
        owner[nfid] = userAddress;

        emit Mint(userAddress, nfid);

        return nfid_document[nfid];
    }

    function burn(address from, uint256 nfid) public onlyOwner {
        if (from == address(0)) {
            revert ZeroAddress();
        }
        if (!_exists(nfid)) {
            revert NonExistingNFID();
        }
        if (!checkNFID(from)) {
            revert AddressHasNoNFID();
        }
        if (!addressAssociatedNFID(from, nfid)) {
            revert AddressHasNoAssociatedNFID();
        }

        nfid_number[from] = 0;
        nfid_document[nfid].userAddress = address(0);
        nfid_document[nfid].nfid = 0;
        owner[nfid] = address(0);

        emit Burn(from, address(0), nfid);
    }
}
