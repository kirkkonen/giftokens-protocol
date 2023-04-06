// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Giftokens is Ownable, ERC721URIStorage {

    IERC20 private _tokenInterface;

    constructor (IERC20 token) ERC721("Giftoken NFTs with balances", "GIFTOKENS") {
        _tokenInterface = token;
    }

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

    function claimNativeCoins(uint _tokenId) public payable returns (bool) {
        Token storage t = tokens[_tokenId];
        //rewrite after adding native contributions to the same array as ERC20
        require(msg.sender == t.beneficiary, "Only available for beneficiaries");
        if(t.nativeBalance > 0) {
            t.beneficiary.transfer(t.nativeBalance);
            t.nativeBalance = 0;
        }
        return true;
    }

    function claimERC20Tokens(uint _tokenId, address _tokenContract) public payable returns (bool) {
        Token storage t = tokens[_tokenId];

        // check contributorMapping if true
        // loop over contributions with _tokenContract 

        //use _tokenInterface to transferFrom



        //     function doStuff() external {
        // address from = msg.sender;

        // _token.transferFrom(from, address(this), 1000);
    // }

        return true;
    }

    function claimNFT(uint256 _tokenId) public payable returns (bool) {
        Token storage t = tokens[_tokenId];
        require(msg.sender == t.beneficiary, "Only available for beneficiaries");
        transferFrom(t.org, t.beneficiary, _tokenId);
        return true;
    }
    

    function acceptERC20Payment(uint _tokenId, address _erc20token, uint _amount) public returns (bool) {
        Token storage t = tokens[_tokenId];
        ERC20contribution memory c = ERC20contribution({contributor:msg.sender, token: _erc20token, amount: _amount});
        t.erc20Contributions.push(c);
        if(t.contributorMapping[msg.sender]==false) {
            t.contributorMapping[msg.sender] = true;
            t.contributorArray.push(msg.sender);
        }
        return true;
    }


    function getERC20contributions(uint _tokenId) public view returns (ERC20contribution[] memory) {
        Token storage t = tokens[_tokenId];
        return t.erc20Contributions;
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

    function getContributorsNativeBalance(uint256 _tokenId, address contributor) public view returns (uint) {
        Token storage t = tokens[_tokenId];
        return t.contributorNativeBalances[contributor];
    }

    function getAllContributors(uint256 _tokenId) public view  returns (address[] memory) {
        Token storage t = tokens[_tokenId];
        return t.contributorArray;
    }

}