// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
contract BirthdayNFT is Ownable, ERC721URIStorage {

    constructor() ERC721("Birthday NFT with tokens", "BIRTHDAY") {}

    struct Token {
      address payable beneficiary;
      address org;
      uint balance;
      mapping(address => uint) contributorBalances;
      address[] contributors;
      string uri;
    }

    mapping(uint256 => Token) tokens;
    uint256[] tokenIds;

    function mint(address payable _beneficiary, uint256 _tokenId, string memory tokenURI) public {
        _mint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, tokenURI);
        Token storage t = tokens[_tokenId];
        t.uri = tokenURI;
        t.beneficiary = _beneficiary;
        t.org = msg.sender;
        tokenIds.push(_tokenId);
        _approve(_beneficiary, _tokenId);
    }

    function acceptPayment(uint256 _tokenId) public payable {
        Token storage t = tokens[_tokenId];
        t.balance += msg.value;
        t.contributorBalances[msg.sender] += msg.value;
        t.contributors.push(msg.sender);
    }

    function claimFunds(uint256 _tokenId) public payable {
        Token storage t = tokens[_tokenId];
        require(msg.sender == t.beneficiary, "Only available for beneficiaries");
        t.beneficiary.transfer(t.balance);
        t.balance = 0;
        _transfer(t.org, t.beneficiary, _tokenId);
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
        return t.balance;
    }

    function getContributorsBalance(uint256 _tokenId, address contributor) public view returns (uint) {
        Token storage t = tokens[_tokenId];
        return t.contributorBalances[contributor];
    }

    function getAllContributors(uint256 _tokenId) public view  returns (address[] memory) {
        Token storage t = tokens[_tokenId];
        return t.contributors;
    }

}