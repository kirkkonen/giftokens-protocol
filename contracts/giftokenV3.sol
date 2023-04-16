// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract GiftokensV3 is Ownable, ERC721URIStorage {

    constructor() ERC721("Giftoken NFTs with balances", "GIFTOKENS") {}

    struct ERC20contribution {
        address contributor;
        address token;
        uint amount;
    }

    struct Token {
        address payable beneficiary;
        address org;
        string uri;
        ERC20contribution[] erc20Contributions;
        mapping(address => uint) contributorNativeBalances;
        uint nativeBalance;
        mapping(address => bool) contributorMapping;
        address[] contributorArray;
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
        transferFrom(t.org, t.beneficiary, _tokenId);
        return true;
    }

    function acceptERC20Payment(uint _tokenId, address _erc20token, uint _amount) public returns (bool) {
        Token storage t = tokens[_tokenId];
        ERC20contribution memory c = ERC20contribution({contributor:msg.sender, token: _erc20token, amount: _amount});
        t.erc20Contributions.push(c);
        return true;
    }

    function getERC20contributions(uint _tokenId) public view returns (ERC20contribution[] memory) {
        Token storage t = tokens[_tokenId];
        return t.erc20Contributions;
    }

    // function getERC20contribution(uint _tokenId, address _contributor) public view returns(ERC20contribution[] memory) {
    //     Token storage t = tokens[_tokenId];

    //     ERC20contribution[] filteredList;

    //     for (uint i=0; i<t.erc20Contributions.length; i++) {
    //         if(t.erc20Contributions[i].contributor == _contributor) {
    //             filteredList.push(t.erc20Contributions[i])
    //         }
    //     }
    //     return filteredList;
    // }

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

    function getContributorsNativeBalance(uint256 _tokenId, address contributor) public view returns (uint) {
        Token storage t = tokens[_tokenId];
        return t.contributorNativeBalances[contributor];
    }

    function getAllContributors(uint256 _tokenId) public view  returns (address[] memory) {
        Token storage t = tokens[_tokenId];
        return t.contributorArray;
    }

}