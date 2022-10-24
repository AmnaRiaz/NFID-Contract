// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NFIDGeneration.sol";

contract NFID is ERC721, ERC721Burnable, Ownable {
    constructor() ERC721("NFID Contract", "NFID") {}

    error ZeroAddress();
    error AddressHasAlreadyNFID();
    error NFIDAlreadyExists();
    error NonExistingNFID();
    error AddressHasNoNFID();
    error AddressHasNoAssociatedNFID();

    event Mint(address indexed userAddress, uint256 nfid);
    event Burn(address indexed userAddress, address indexed to, uint256 nfid);

    struct NFIDDocument {
        address to;
        uint256 nfid;
        uint256 deadline;
    }

    mapping(address => uint256) nfid_number;
    mapping(uint256 => NFIDDocument) public nfid_document;


    function existsNFID(uint256 nfid) public view returns(bool) {
        return nfid_document[nfid].to != address(0);
    }

    function checkNFID(address userAddress) public view returns(bool) {
        return nfid_number[userAddress] != 0;
    }

    function findNFID(address userAddress) public view returns(uint256) {
        return nfid_number[userAddress];
    }

    function addressAssociatedNFID(address from, uint256 nfid) public view returns(bool) {
        return nfid_number[from] == nfid;
    }

    function _mint(address to, uint256 nfid, uint256 deadline) private {
        if(to == address(0)) {
            revert ZeroAddress();
        }
        if(checkNFID(to)) {
            revert AddressHasAlreadyNFID(); 
        }
        if(existsNFID(nfid)) {
            revert NFIDAlreadyExists();
        }

        nfid_document[nfid].nfid = nfid;
        nfid_document[nfid].to = to;
        nfid_document[nfid].deadline = deadline;

        nfid_number[to] = nfid;
        
        emit Mint(to, nfid);
    }

     function mint(
        address _signer,
        address to,
        string memory _message,
        bytes memory signature,
        uint256 nfid,
        uint256 deadline
    ) public returns (NFIDDocument memory) {
        bytes32 messageHash = getMessageHash(to, _message, nfid,  deadline);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

    (recoverSigner(ethSignedMessageHash, signature) == _signer);
         _mint(to, nfid, deadline);
    
       // return nfid_document[nfid];
    }

    function _burn(address from, uint256 nfid) private onlyOwner  {
        nfid_number[from] = 0;
        nfid_document[nfid].to = address(0);
        nfid_document[nfid].nfid = 0;
        nfid_document[nfid].deadline = 0;

        emit Burn(from, address(0), nfid);
    }     

    function burn(address from, uint256 nfid) public onlyOwner {
        if(from == address(0)) {
            revert ZeroAddress();
        }
        if(!existsNFID(nfid)){
            revert NonExistingNFID();
        }
        if(!checkNFID(from)){
            revert AddressHasNoNFID();
        }
        if(!addressAssociatedNFID(from, nfid)){
            revert AddressHasNoAssociatedNFID(); 
        }

       _burn(from, nfid); //burns the NFID
    }

    function generateNFID(string memory x, string memory y) external pure returns (uint256){
        return NFIDGeneration.generateNFID(x,y);
    }

    function getMessageHash(
        address to,
        string memory _message,
        uint256 nfid ,
        uint256 deadline
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(to,  _message, nfid, deadline));
    }

function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }


 function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

}
}