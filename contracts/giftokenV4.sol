// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";


contract Giftokens is Ownable, ERC721URIStorage {

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
        mapping(address => Contribution[]) contributionMapping;
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


    function acceptPayment(uint _tokenId, IERC20 token, uint _amount) public returns (bool) {
        Token storage t = tokens[_tokenId];
        Contribution memory c = Contribution({ contributor: msg.sender, amount: _amount});
        t.contributionMapping[address(token)].push(c);

        token.transferFrom(msg.sender, address(this), _amount);

        if(t.currencyMapping[address(token)]==false) {
            t.currencyMapping[address(token)] = true;
            t.currencyArray.push(address(token));
        }

        return true;
    }


    function claimFunds(uint _tokenId, IERC20 token, address _contributor) public payable returns (bool) {
        Token storage t = tokens[_tokenId];
        require(msg.sender == t.beneficiary, "Only available for beneficiaries");

        Contribution[] storage contributions = t.contributionMapping[address(token)];

        if (address(token) == 0x0000000000000000000000000000000000000000) {
            for (uint i=0; i<contributions.length; i++) {
                if (contributions[i].contributor == _contributor) {
                    t.beneficiary.transfer(contributions[i].amount);
                }
            }

        } else {

            for (uint i=0; i<contributions.length; i++) {
                if (contributions[i].contributor == _contributor) {
                    token.transferFrom(address(this), t.beneficiary, contributions[i].amount);
                }
            }
        }

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
        FullContribution[] memory fca;

        for (uint i=0; i<t.currencyArray.length; i++) {

            address _tokenAddress = t.currencyArray[i];
            Contribution[] memory _contributions = t.contributionMapping[_tokenAddress];

            for (uint a=0; a<_contributions.length; a++) {

                FullContribution memory fc = FullContribution({
                    token: 0x0000000000000000000000000000000000000000, 
                    contributor: 0x0000000000000000000000000000000000000000, 
                    amount: 0
                });

                fc.token = _tokenAddress;
                fc.contributor = _contributions[a].contributor;
                fc.amount = _contributions[a].amount;

                fc = fca[a*(i+1)];
            }
        }

        return fca;
    }

    function getTokenIds() public view returns (uint256[] memory) {
        return tokenIds;
    }

    function getBeneficiary(uint _tokenId) public view returns (address) {
        Token storage t = tokens[_tokenId];
        return t.beneficiary;
    }


}