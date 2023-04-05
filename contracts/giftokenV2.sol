// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract Giftokens is Ownable, ERC721URIStorage {     

    constructor() ERC721("Giftoken NFTs with balances", "GIFTOKENS") {}

    struct Token { 
      address payable beneficiary;
      address org;
      uint nativeBalance;
      mapping(address => uint) tokenBalances;
      mapping(address => uint) contributorNativeBalances;
      mapping(address => mapping(address => uint)) contributorTokenBalances;
      mapping(address => bool) contributorMapping;
      address[] contributorArray;
      address[] ERC20Array;
      string uri;
    }

    mapping(uint256 => Token) tokens;
    uint256[] tokenIds;

    function mint(address payable _beneficiary, uint256 _tokenId, string memory tokenURI) public returns (bool) {        
        _mint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, tokenURI);
        Token storage t = tokens[_tokenId];
        t.uri = tokenURI;
        t.beneficiary = _beneficiary;
        t.org = msg.sender;
        tokenIds.push(_tokenId);
        _approve(_beneficiary, _tokenId);
        return true;
    }

    function acceptERC20Payment(uint256 _tokenId, address _ERC20contract, uint _amount) public payable returns (bool) {
        Token storage t = tokens[_tokenId];
        t.contributorTokenBalances[_ERC20contract][msg.sender] += _amount;
        if(t.contributorMapping[msg.sender]==false) {
            t.contributorMapping[msg.sender] = true;
            t.contributorArray.push(msg.sender);
        }
        if(t.tokenBalances[_ERC20contract]==0){
            t.ERC20Array.push(_ERC20contract);
        }
        t.tokenBalances[_ERC20contract] += _amount;
        return true;
    }

    function acceptNativePayment(uint256 _tokenId) public payable returns (bool) {
        Token storage t = tokens[_tokenId];
        t.nativeBalance += msg.value;
        t.contributorNativeBalances[msg.sender] += msg.value;
        if(t.contributorMapping[msg.sender]==false) {
            t.contributorMapping[msg.sender] = true;
            t.contributorArray.push(msg.sender);
        }
        return true;    
    }

    function claimFunds(uint256 _tokenId) public payable returns (bool) {
        Token storage t = tokens[_tokenId];
        require(msg.sender == t.beneficiary, "Only available for beneficiaries");
        //sending native tokens
        if(t.nativeBalance > 0) {
            t.beneficiary.transfer(t.nativeBalance);
            t.nativeBalance = 0;
        }
        //updating ERC20 token balances
        uint ERC20ArrayLength = t.ERC20Array.length;
        if(ERC20ArrayLength > 0) {
            for (uint i=0; i<ERC20ArrayLength; i++) {
            t.tokenBalances[t.ERC20Array[i]] = 0;
        }
        }
        transferFrom(t.org, t.beneficiary, _tokenId);
        return true;
    }

    function getTokenIds() public view returns (uint256[] memory) {
        return tokenIds;
    }

    function getBeneficiary(uint _tokenId) public view returns (address) {
        Token storage t = tokens[_tokenId];
        return t.beneficiary;
    }

    function getTokenBalance(uint _tokenId) public view returns (uint) {
        Token storage t = tokens[_tokenId];
        return t.nativeBalance;
    }

    function getERC20Balance(uint256 _tokenId, address _ERC20contract) public view returns (uint) {
        Token storage t = tokens[_tokenId];
        return t.tokenBalances[_ERC20contract];
    }

    function getContributorsERC20Balance(uint256 _tokenId, address contributor, address _ERC20contract) public view returns (uint) {
        Token storage t = tokens[_tokenId];
        return t.contributorTokenBalances[_ERC20contract][contributor];
    }

    function getContributorsNativeBalance(uint256 _tokenId, address contributor) public view returns (uint) {
        Token storage t = tokens[_tokenId];
        return t.contributorNativeBalances[contributor];
    }

    function getAllContributors(uint256 _tokenId) public view  returns (address[] memory) {
        Token storage t = tokens[_tokenId];
        return t.contributorArray;
    }

    function getERC20contracts(uint256 _tokenId) public view returns (address[] memory) {
        Token storage t=tokens[_tokenId];
        return t.ERC20Array;
    }

}