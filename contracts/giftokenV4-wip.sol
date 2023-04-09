// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Giftokens is Ownable, ERC721URIStorage {

    // IERC20 private _tokenInterface;

    // constructor (IERC20 token) ERC721("Giftoken NFTs with balances", "GIFTOKENS") {
    //     _tokenInterface = token;
    // }

    constructor() ERC721("Giftoken NFTs with balances", "GIFTOKENS") {}


    struct Contribution {
        address contributor;
        uint amount;
    }

    struct FullContribution {
        address token;
        address contributor;
        uint amount;
    }

    struct Token { 
        address payable beneficiary;
        address org;
        string uri;
        // Contribution[] contributions;
        // mapping(address => uint) contributorNativeBalances;
        // uint nativeBalance;
        mapping(address => Contribution[]) contributionMapping;
        // mapping(address => bool) contributorMapping;
        mapping(address => bool) currencyMapping;
        address[] currencyArray;
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

    // function acceptNativePayment(uint256 _tokenId) public payable returns (bool) {
    //     Token storage t = tokens[_tokenId];
    //     Contribution memory c = Contribution({ token: 0, amount: _amount});
    //     t.contributorMapping[msg.sender].push(c);


    //     // rewrite
    //     // add to currencyMapping

    //     // t.nativeBalance += msg.value;
    //     // t.contributorNativeBalances[msg.sender] += msg.value;
    //     if(t.contributorMapping[msg.sender]==false) {
    //         t.contributorMapping[msg.sender] = true;
    //         t.contributorArray.push(msg.sender);
    //     }
    //     return true;    
    // }

    // function acceptPayment(uint _tokenId, address _erc20token, uint _amount) 

    function acceptPayment(uint _tokenId, IERC20 token, uint _amount) public returns (bool) {
        Token storage t = tokens[_tokenId];
        Contribution memory c = Contribution({ contributor: msg.sender, amount: _amount});
        t.contributionMapping[token].push(c);
        //t.contributions.push(c);

        token.transferFrom(msg.sender, address(this), _amount);

        if(t.currencyMapping[token]==false) {
            t.currencyMapping[token] = true;
            t.currencyArray.push(token);
        }
        // if(t.currencyMapping[_erc20token]==false) {
        //     t.currencyMapping[_erc20token] = true;
        // }
        return true;
    }

    // function claimNativeCoins(uint _tokenId) public payable returns (bool) {
    //     Token storage t = tokens[_tokenId];
    //     require(msg.sender == t.beneficiary, "Only available for beneficiaries");

    //     //rewrite after adding native contributions to the same array as ERC20


    //     // if(t.nativeBalance > 0) {
    //     //     t.beneficiary.transfer(t.nativeBalance);
    //     //     t.nativeBalance = 0;
    //     // }
    //     return true;
    // }

    function claimFunds(uint _tokenId, IERC20 token, address _contributor) public payable returns (bool) {
        Token storage t = tokens[_tokenId];
        require(msg.sender == t.beneficiary, "Only available for beneficiaries");

        Contribution[] storage contributions = t.contributionMapping[token];

        if (token == 0) {
            for (uint i=0; i<contributions.length; i++) {
                if (contributions[i].contributor == _contributor) {
                    t.beneficiary.transfer(contributions[i].amount)
                }
            }

        } else {

            for (uint i=0; i<contributions.length; i++) {
                if (contributions[i].contributor == _contributor) {
                    token.transferFrom(address(this), t.beneficiary, contributions[i].amount);
                }
            }
        }

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


    function getContributions(uint _tokenId) public view returns (FullContribution[] memory) {
        Token storage t = tokens[_tokenId];
        FullContribution[] fca;

        for (uint i=0; i<t.currencyArray.length; i++) {
            FullContribution memory fc = FullContribution({});
            fc.token = currencyArray[i];
            fc.contributor = t.contributionMapping[currencyArray[i]].contributor;
            fc.amount = t.contributionMapping[currencyArray[i]].amount;
            fca.push(fc);
        }



        // Contribution memory c = Contribution({ contributor: msg.sender, amount: _amount});

        //rewrite

            // for (uint i=0; i<contributions.length; i++) {
            //     token.transferFrom(address(this), msg.sender, contributions[i].amount);
            // }

        return fca;
    }

    function getTokenIds() public view returns (uint256[] memory) {
        return tokenIds;
    }

    function getBeneficiary(uint _tokenId) public view returns (address) {
        Token storage t = tokens[_tokenId];
        return t.beneficiary;
    }

    function getAllContributors(uint256 _tokenId) public view  returns (address[] memory) {
        Token storage t = tokens[_tokenId];
        return t.contributorArray;
    }


    // function getTokenBalance(uint _tokenId) public view returns (uint) {
    //     Token storage t = tokens[_tokenId];
    //     return t.nativeBalance;
    // }

    // function getContributorsNativeBalance(uint256 _tokenId, address contributor) public view returns (uint) {
    //     Token storage t = tokens[_tokenId];
    //     return t.contributorNativeBalances[contributor];
    // }


}