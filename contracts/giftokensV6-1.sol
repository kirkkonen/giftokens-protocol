// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import 'hardhat/console.sol';

contract GiftokensV6 is Ownable, ERC721URIStorage {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for ERC20;

    address public relayer;

    constructor(address _relayer) ERC721("Giftoken NFTs with balances", "GIFTOKENS") {
        relayer = _relayer;
    }

    struct Contribution {
        address contributor;
        uint256 amount;
    }

    struct FullContribution {
        address token;
        address contributor;
        uint256 amount;
    }

    struct Token {
        address payable beneficiary;
        address org;
        string uri;
        mapping(address => Contribution[]) contributionMapping;
        EnumerableSet.AddressSet currencySet;
        uint256 contributionsCount;
    }

    mapping(uint256 => Token) tokens;
    EnumerableSet.UintSet tokenIds;

    function mint(
        address payable _beneficiary,
        uint256 _tokenId,
        string memory tokenURI
    ) public returns (bool) {
        _mint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, tokenURI);
        _approve(relayer, _tokenId);

        if(tokenIds.contains(_tokenId)) {
            revert();
        } else {
            Token storage t = tokens[_tokenId];
            t.uri = tokenURI;
            t.beneficiary = _beneficiary;
            t.org = msg.sender;
            tokenIds.add(_tokenId);
            return true;
        }
    }

    function acceptPayment(
        uint256 _tokenId,
        address token,
        uint256 _amount
    ) public payable returns (bool) {
        Token storage t = tokens[_tokenId];

        require(
            tokenIds.contains(_tokenId), 
            'token does not exist'
            );

        if (address(token) == address(0)) {
            require(
                msg.value>0, 
                'message value is empty'
            );

            console.log("Accept Payment", msg.value);
            Contribution memory c = Contribution({
                contributor: msg.sender,
                amount: msg.value
            });
            t.contributionMapping[address(token)].push(c);
        } else {
            Contribution memory c = Contribution({
                contributor: msg.sender,
                amount: _amount
            });
            ERC20 erc20 = ERC20(token);
            erc20.safeTransferFrom(msg.sender, address(this), _amount);

            t.contributionMapping[address(token)].push(c);
        }

        t.currencySet.add(address(token));
        t.contributionsCount++;
        return true;
    }

    function claimFunds(
        uint256 _tokenId,
        IERC20 token,
        address _contributor
    ) public payable returns (bool) {
        Token storage t = tokens[_tokenId];

        //added in v6 for non-owned tokens
        if(t.beneficiary == address(0)){
            t.beneficiary = payable(msg.sender);
        }
        
        require(
            msg.sender == t.beneficiary,
            "Only available for beneficiaries"
        );

        Contribution[] storage contributions = t.contributionMapping[
            address(token)
        ];

        //added amount = 0 on 23.04.2023
        if (address(token) == address(0)) {
            for (uint256 i = 0; i < contributions.length; i++) {
                if (contributions[i].contributor == _contributor) {
                    t.beneficiary.transfer(contributions[i].amount);
                    contributions[i].amount = 0;
                }
            }
        } else {
            for (uint256 i = 0; i < contributions.length; i++) {
                if (contributions[i].contributor == _contributor) {
                    token.transfer(t.beneficiary, contributions[i].amount);
                    contributions[i].amount = 0;
                }
            }
        }

        return true;
    }

    function claimNFT(uint256 _tokenId, address payable _beneficiary) public payable returns (bool) {
        Token storage t = tokens[_tokenId];

        //added in v6 for non-owned tokens
        if(t.beneficiary == address(0)){
            t.beneficiary = _beneficiary;
        }

        // require(
        //     msg.sender == t.beneficiary,
        //     "Only available for beneficiaries"
        // );
        
        transferFrom(t.org, t.beneficiary, _tokenId);
        return true;
    }

    function getContributions(
        uint256 _tokenId
    ) public view returns (FullContribution[] memory) {
        Token storage t = tokens[_tokenId];
        FullContribution[] memory fca = new FullContribution[](
            t.contributionsCount
        );
        uint256 j;

        for (uint256 i = 0; i < t.currencySet.length(); i++) {

            address _tokenAddress = t.currencySet.at(i);
            Contribution[] memory _contributions = t.contributionMapping[
                _tokenAddress
            ];

            for (uint256 a = 0; a < _contributions.length; a++) {
                fca[j++] = FullContribution({
                    token: _tokenAddress,
                    contributor: _contributions[a].contributor,
                    amount: _contributions[a].amount
                });
            }
        }

        return fca;
    }

    function getTokenIds() public view onlyOwner returns (uint256[] memory) {
        return tokenIds.values();
    }

    function getOrg(uint256 _tokenId) public view returns (address) {
        Token storage t = tokens[_tokenId];
        return t.org;
    }

    function getBeneficiary(uint256 _tokenId) public view returns (address) {
        Token storage t = tokens[_tokenId];
        return t.beneficiary;
    }
}