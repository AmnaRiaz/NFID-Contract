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
    event MintingRequest(uint256 miner_nfid, address miner_pubkey, uint256 new_nfid, address new_pubkey, uint8 role);

    struct NFIDDocument {
        address userAddress;
        uint256 nfid;
        uint role;
    }
  
   struct MinterRequest {
        uint256 miner_nfid;
        address miner_pubkey;
        uint256 new_nfid;
        address new_pubkey;
        uint8 role;
    }


     mapping(address => MinterRequest) public  mint_request;
    mapping(address => uint256) nfid_number;
    mapping(uint256 => NFIDDocument) public nfid_document;
    mapping(uint256 => address) public owner;


     function exists(uint256 nfid) internal view  returns(bool) {
        return owner[nfid] != address(0);
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

    function mintingRequest(uint256 miner_nfid, address miner_pubkey, uint256 new_nfid, address new_pubkey, uint8 role) internal {
        mint_request[miner_pubkey].miner_pubkey = miner_pubkey;
        mint_request[miner_pubkey].miner_nfid = miner_nfid;
        mint_request[miner_pubkey].new_nfid = new_nfid;
        mint_request[miner_pubkey].new_pubkey = new_pubkey;
        mint_request[miner_pubkey].role = role;

        emit MintingRequest(miner_nfid, miner_pubkey, new_nfid, new_pubkey, role);
    }

       function approve(address miner_pubkey) public onlyOwner  {
         if(mint_request[miner_pubkey].new_pubkey == address(0)) {
            revert ZeroAddress();
        }
        if(checkNFID(mint_request[miner_pubkey].new_pubkey)) {
            revert AddressHasAlreadyNFID(); 
        }
        if(_exists(mint_request[miner_pubkey].new_nfid)) {
            revert NFIDAlreadyExists();
        }

         _mint(miner_pubkey); //It approves the actual mint 
    }

        function _mint(address miner_pubkey) private onlyOwner  returns(NFIDDocument memory)  {
        

        nfid_number[mint_request[miner_pubkey].new_pubkey] = mint_request[miner_pubkey].new_nfid;
        nfid_document[mint_request[miner_pubkey].new_nfid].userAddress = mint_request[miner_pubkey].new_pubkey;
        nfid_document[mint_request[miner_pubkey].new_nfid].nfid = mint_request[miner_pubkey].new_nfid;
        nfid_document[mint_request[miner_pubkey].new_nfid].role = mint_request[miner_pubkey].role;
        owner[mint_request[miner_pubkey].new_nfid] = mint_request[miner_pubkey].new_pubkey;

        clearMintRequest(miner_pubkey);
        
        emit Mint(mint_request[miner_pubkey].new_pubkey, mint_request[miner_pubkey].new_nfid);
        return nfid_document[mint_request[miner_pubkey].new_nfid];
    }

    function mint(uint256 miner_nfid, address miner_pubkey, uint256 new_nfid, address new_pubkey, uint8 role) public onlyOwner  {
      mintingRequest(miner_nfid, miner_pubkey, new_nfid, new_pubkey, role); //sends a minting request
    }

    
     function clearMintRequest(address miner_pubkey) private {
        mint_request[miner_pubkey].miner_pubkey = address(0);
        mint_request[miner_pubkey].miner_nfid = 0;
        mint_request[miner_pubkey].new_nfid = 0;
        mint_request[miner_pubkey].new_pubkey = address(0);
        mint_request[miner_pubkey].role = 0;
    }


    function _burn(address from, uint256 nfid) private onlyOwner  {

        nfid_number[from] = 0;
        nfid_document[nfid].userAddress = address(0);
        nfid_document[nfid].nfid = 0;
        nfid_document[nfid].role = 0;
        owner[nfid] = address(0);

        emit Burn(from, address(0), nfid);
    }     

    function burn(address from, uint256 nfid) public onlyOwner {
        if(from == address(0)) {
            revert ZeroAddress();
        }
        if(!_exists(nfid)){
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
}