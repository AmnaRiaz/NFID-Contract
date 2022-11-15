// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./NFIDGeneration.sol";

contract NFID is ERC721, ERC721Burnable, Ownable {
    constructor() ERC721("NFID Contract", "NFID") {}

    /*
    ERROR MESSAGES
*/

    error ZeroAddress();
    error Empty();
    error AddressHasAlreadyNFID();
    error NFIDAlreadyExists();
    error NonExistingNFID();
    error AddressHasNoNFID();
    error AddressHasNoAssociatedNFID();
    error SignatureVerificationFailed();

    /*
EVENTS FOR MINT, UPDATE AND BURN
*/

    event Mint(address indexed userAddress, uint256 nfid);
    event Update(address indexed userAddress, uint256 nfid, string docDID);
    event Burn(address indexed userAddress, address indexed to, uint256 nfid);

    struct DIDDocument {
        string didDoc;
        mapping(uint256 => bool) controller;
    }

    mapping(address => uint256) nfid_number;
    mapping(uint256 => DIDDocument) public nfid_document;

    /*
    Checks NFID should not be equal to zero
*/

    function existsNFID(uint256 nfid) public view returns (bool) {
        return nfid_document[nfid].controller[nfid] != false;
    }

    /*
checks user address should not be equal to zero
*/

    function checkNFID(address userAddress) public view returns (bool) {
        return nfid_number[userAddress] != 0;
    }

    /*
checks function returns an NFID with address 
*/

    function findNFID(address userAddress) public view returns (uint256) {
        return nfid_number[userAddress];
    }

    /*
checks eithers an address is accociated to an NFId or not
*/

    function addressAssociatedNFID(address from, uint256 nfid)
        public
        view
        returns (bool)
    {
        return nfid_number[from] == nfid;
    }

    function getDIDDocument() public view returns (string memory) {
        address from = msg.sender;
        // if (!addressAssociatedNFID(from, nfid)) {
        //     revert AddressHasNoAssociatedNFID();
        // }

        return nfid_document[nfid_number[from]].didDoc;
    }

    function checkController() public view returns (bool) {
        address from = msg.sender;
        uint256 nfid = nfid_number[from];
        return nfid_document[nfid].controller[nfid];
    }

    function _mint(
        address to,
        uint256 nfid,
        string memory didDoc
    ) private {
        if (to == address(0)) {
            revert ZeroAddress();
        }
        if (checkNFID(to)) {
            revert AddressHasAlreadyNFID();
        }
        if (existsNFID(nfid)) {
            revert NFIDAlreadyExists();
        }

        nfid_document[nfid].controller[nfid] = true;
        nfid_document[nfid].didDoc = didDoc;

        nfid_number[to] = nfid;

        emit Mint(to, nfid);
    }

    /*
 @desc - This function will do three things First it will check and verify the signature , second it will generate the NFID, third It will mint NFID.
 @param - address _signer:  This is the address of the signer, who signed the token.
        address to : This is the address of the person who's getting the signed token.
        string memory _message : This is the secret message.
        bytes memory signature: This is the generated signature.
        uint256 deadline:  Its a deadline use in signature generation.
        string memory didDoc :  Its string form of DID Document.
        string memory x:  X public key.
        string memory y : Y public key.
*/

    function mint(
        address _signer,
        string memory _message,
        bytes memory signature,
        uint256 deadline,
        string memory didDoc,
        string memory x,
        string memory y
    ) public {
        address to = msg.sender;

        if (bytes(didDoc).length == 0) {
            revert Empty();
        }

        uint256 nfid = NFIDGeneration.generateNFID(x, y);
        bytes32 messageHash = getMessageHash(to, _message, deadline);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        if (recoverSigner(ethSignedMessageHash, signature) == _signer) {
            _mint(to, nfid, didDoc);
        } else {
            revert SignatureVerificationFailed();
        }
    }

    /*
 @desc - This function will update the values of did document after converting them to string.
 @param - String memeory docDid : Its string form of DID Document
      uint256 nfid: It is the already generate nfid.
 */

    function update(uint256 nfid, string memory docDID) public {
        address from = msg.sender;
        require(
            nfid_document[nfid_number[from]].controller[nfid] == true,
            "Caller is not the controller of nfid"
        );

        if (bytes(docDID).length == 0) {
            revert Empty();
        }

        if (from == address(0)) {
            revert ZeroAddress();
        }
        if (!existsNFID(nfid)) {
            revert NonExistingNFID();
        }
        if (!checkNFID(from)) {
            revert AddressHasNoNFID();
        }
        if (!addressAssociatedNFID(from, nfid)) {
            revert AddressHasNoAssociatedNFID();
        }

        nfid_document[nfid].didDoc = docDID;

        emit Update(from, nfid, docDID);
    }

    function _burn(address from, uint256 nfid) private {
        require(
            nfid_document[nfid_number[from]].controller[nfid] == true,
            "Caller is not the controller of nfid"
        );

        nfid_number[from] = 0;
        nfid_document[nfid_number[from]].controller[nfid] == false;
        nfid_document[nfid].didDoc = "";

        emit Burn(from, address(0), nfid);
    }

    /*
 @desc - It will burn the NFID and everything related to it.
 @param - uint256 nfid: It is the already generate nfid it will take as a parameter and will burn everything assocoiated to it.
*/

    function burnNfid(uint256 nfid) public {
        address from = msg.sender;

        if (from == address(0)) {
            revert ZeroAddress();
        }
        if (!existsNFID(nfid)) {
            revert NonExistingNFID();
        }
        if (!checkNFID(from)) {
            revert AddressHasNoNFID();
        }
        if (!addressAssociatedNFID(from, nfid)) {
            revert AddressHasNoAssociatedNFID();
        }

        _burn(from, nfid);
    }

    /*
 @desc - It will generate the NFID.
 @param - ( String memory x, string memory y  ) It will take two strings as input .
@returns - this function returns (uint256) NFID.
*/

    function generateNFID(string memory x, string memory y)
        external
        pure
        returns (uint256)
    {
        return NFIDGeneration.generateNFID(x, y);
    }

    /*
 @desc - It will generate the Message hash for signature.
 @param - ( address, string memory, uint256 ),
   to address: Address of the person whome you want to assign.
    Message: A secret message to send.
    deadline: deadline time to expire the signature.
 @returns - (Bytes32 ) This function returns a 32 byte hash.
*/

    function getMessageHash(
        address to,
        string memory _message,
        uint256 deadline
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(to, _message, deadline));
    }

    /*
@desc - It will get the message signed from Ethereum as will return that verifed hash.
@param - ( bytes32 ) It will take bytes 32 hash. generate by kecckak and convert it into Eth Signed message hash (using ethereum function to signed by a wallet)
@returns - (Bytes32 ) This function returns a singed message hash.
*/

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
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    /*
@desc - It will double check the hash if it's valied or not.
@param - ( bytes32, bytes 32  ) It will take two bytes32 hashes. One is generate from Simple kecckak and other the signature that is generated by Eth method signature from web3  .
@returns - ( Address ) This function returns A singers address who has singned the message.
*/
    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /*
@desc - It will split the generated signature into three part and veirfy if it's correct or not.
@param - ( bytes memory sig ) It will take bytes memory signature thai is generated from web3 and split it intp three parts to verify either signature the verified or not.  .
@returns - (Bytes33 r, bytes32 s, uint8 v  ) This function returns r,s,v verification of singature.
*/

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
} // SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./NFIDGeneration.sol";

contract NFID is ERC721, ERC721Burnable, Ownable {
    constructor() ERC721("NFID Contract", "NFID") {}

    /*
    ERROR MESSAGES
*/

    error ZeroAddress();
    error Empty();
    error AddressHasAlreadyNFID();
    error NFIDAlreadyExists();
    error NonExistingNFID();
    error AddressHasNoNFID();
    error AddressHasNoAssociatedNFID();
    error SignatureVerificationFailed();

    /*
EVENTS FOR MINT, UPDATE AND BURN
*/

    event Mint(address indexed userAddress, uint256 nfid);
    event Update(address indexed userAddress, uint256 nfid, string docDID);
    event Burn(address indexed userAddress, address indexed to, uint256 nfid);

    struct DIDDocument {
        string didDoc;
        mapping(uint256 => bool) controller;
    }

    mapping(address => uint256) nfid_number;
    mapping(uint256 => DIDDocument) public nfid_document;

    /*
    Checks NFID should not be equal to zero
    */

    function existsNFID(uint256 nfid) public view returns (bool) {
        return nfid_document[nfid].controller[nfid] != false;
    }

    /*
checks user address should not be equal to zero
    */

    function checkNFID(address userAddress) public view returns (bool) {
        return nfid_number[userAddress] != 0;
    }

    /*
checks function returns an NFID with address 
*/

    function findNFID(address userAddress) public view returns (uint256) {
        return nfid_number[userAddress];
    }

    /*
checks eithers an address is accociated to an NFId or not
*/

    function addressAssociatedNFID(address from, uint256 nfid)
        public
        view
        returns (bool)
    {
        return nfid_number[from] == nfid;
    }

    function getDIDDocument() public view returns (string memory) {
        address from = msg.sender;
        // if (!addressAssociatedNFID(from, nfid)) {
        //     revert AddressHasNoAssociatedNFID();
        // }

        return nfid_document[nfid_number[from]].didDoc;
    }


    function checkController() public view returns (bool) {
        address from = msg.sender;
        uint256 nfid = nfid_number[from];
        return nfid_document[nfid].controller[nfid];
    }

    function _mint(
        address to,
        uint256 nfid,
        string memory didDoc
    ) private {
        if (to == address(0)) {
            revert ZeroAddress();
        }
        if (checkNFID(to)) {
            revert AddressHasAlreadyNFID();
        }
        if (existsNFID(nfid)) {
            revert NFIDAlreadyExists();
        }

        nfid_document[nfid].controller[nfid] = true;
        nfid_document[nfid].didDoc = didDoc;

        nfid_number[to] = nfid;

        emit Mint(to, nfid);
    }

    /*
 @desc - This function will do three things First it will check and verify the signature , second it will generate the NFID, third It will mint NFID.
 @param - address _signer:  This is the address of the signer, who signed the token.
        address to : This is the address of the person who's getting the signed token.
        string memory _message : This is the secret message.
        bytes memory signature: This is the generated signature.
        uint256 deadline:  Its a deadline use in signature generation.
        string memory didDoc :  Its string form of DID Document.
        string memory x:  X public key.
        string memory y : Y public key.
*/

    function mint(
        address _signer,
        string memory _message,
        bytes memory signature,
        uint256 deadline,
        string memory didDoc,
        string memory x,
        string memory y
    ) public {
        address to = msg.sender;

        if (bytes(didDoc).length == 0) {
            revert Empty();
        }

        uint256 nfid = NFIDGeneration.generateNFID(x, y);
        bytes32 messageHash = getMessageHash(to, _message, deadline);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        if (recoverSigner(ethSignedMessageHash, signature) == _signer) {
            _mint(to, nfid, didDoc);
        } else {
            revert SignatureVerificationFailed();
        }
    }

    /*
 @desc - This function will update the values of did document after converting them to string.
 @param - String memeory docDid : Its string form of DID Document
      uint256 nfid: It is the already generate nfid.
 */

    function update(uint256 nfid, string memory docDID) public {
        address from = msg.sender;
        require(
            nfid_document[nfid_number[from]].controller[nfid] == true,
            "Caller is not the controller of nfid"
        );

        if (bytes(docDID).length == 0) {
            revert Empty();
        }

        if (from == address(0)) {
            revert ZeroAddress();
        }
        if (!existsNFID(nfid)) {
            revert NonExistingNFID();
        }
        if (!checkNFID(from)) {
            revert AddressHasNoNFID();
        }
        if (!addressAssociatedNFID(from, nfid)) {
            revert AddressHasNoAssociatedNFID();
        }

        nfid_document[nfid].didDoc = docDID;

        emit Update(from, nfid, docDID);
    }

    function _burn(address from, uint256 nfid) private {
        require(
            nfid_document[nfid_number[from]].controller[nfid] == true,
            "Caller is not the controller of nfid"
        );

        nfid_number[from] = 0;
        nfid_document[nfid_number[from]].controller[nfid] == false;
        nfid_document[nfid].didDoc = "";

        emit Burn(from, address(0), nfid);
    }

    /*
 @desc - It will burn the NFID and everything related to it.
 @param - uint256 nfid: It is the already generate nfid it will take as a parameter and will burn everything assocoiated to it.
*/

    function burnNfid(uint256 nfid) public {
        address from = msg.sender;

        if (from == address(0)) {
            revert ZeroAddress();
        }
        if (!existsNFID(nfid)) {
            revert NonExistingNFID();
        }
        if (!checkNFID(from)) {
            revert AddressHasNoNFID();
        }
        if (!addressAssociatedNFID(from, nfid)) {
            revert AddressHasNoAssociatedNFID();
        }

        _burn(from, nfid);
    }

    /*
 @desc - It will generate the NFID.
 @param - ( String memory x, string memory y  ) It will take two strings as input .
@returns - this function returns (uint256) NFID.
*/

    function generateNFID(string memory x, string memory y)
        external
        pure
        returns (uint256)
    {
        return NFIDGeneration.generateNFID(x, y);
    }

    /*
 @desc - It will generate the Message hash for signature.
 @param - ( address, string memory, uint256 ),
   to address: Address of the person whome you want to assign.
    Message: A secret message to send.
    deadline: deadline time to expire the signature.
 @returns - (Bytes32 ) This function returns a 32 byte hash.
*/

    function getMessageHash(
        address to,
        string memory _message,
        uint256 deadline
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(to, _message, deadline));
    }

    /*
@desc - It will get the message signed from Ethereum as will return that verifed hash.
@param - ( bytes32 ) It will take bytes 32 hash. generate by kecckak and convert it into Eth Signed message hash (using ethereum function to signed by a wallet)
@returns - (Bytes32 ) This function returns a singed message hash.
*/

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
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    /*
@desc - It will double check the hash if it's valied or not.
@param - ( bytes32, bytes 32  ) It will take two bytes32 hashes. One is generate from Simple kecckak and other the signature that is generated by Eth method signature from web3  .
@returns - ( Address ) This function returns A singers address who has singned the message.
*/
    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /*
@desc - It will split the generated signature into three part and veirfy if it's correct or not.
@param - ( bytes memory sig ) It will take bytes memory signature thai is generated from web3 and split it intp three parts to verify either signature the verified or not.  .
@returns - (Bytes33 r, bytes32 s, uint8 v  ) This function returns r,s,v verification of singature.
*/

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
