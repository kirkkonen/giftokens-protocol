import { expect } from "chai";

import { ethers, network } from "hardhat";
import hre from 'hardhat'
import '@nomiclabs/hardhat-ethers'
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
// import { erc20Abi } from '../abi/erc20Abi.js'


// import { Contract, Signer } from "ethers";

describe("Giftokens", function () {

  async function deployGiftoken() {
    const [owner, ben, org, gifter] = await hre.ethers.getSigners()
    const Giftokens = await hre.ethers.getContractFactory('contracts/giftokenV5.sol:Giftokens')
    const gifttoken = await Giftokens.deploy()
    await gifttoken.deployed()

    // await network.provider.request({
    //   method: 'hardhat_impersonateAccount',
    //   params: [sender!.address],
    // })

    console.log(
      'owner: ', owner.address,
      'ben: ', ben.address,
      'org: ', org.address,
      'gifter: ', gifter.address
    )

    return { ben, org, gifter, gifttoken }
  }

  async function deployErc20() {
    const [erc20owner] = await hre.ethers.getSigners()
    const Erc20 = await hre.ethers.getContractFactory('contracts/standardErc20.sol:Erc20')
    const erc20 = await Erc20.deploy(10000)
    await erc20.deployed()

    console.log(
      'erc20: ', erc20.address,
      'erc20 address: ', erc20.address,
      'erc20 owner: ', erc20owner.address
    )

    return { erc20, erc20owner }

  }


  it('mints, accepts payment and returns contribution', async function () {
    const { ben, gifter, org, gifttoken } = await loadFixture(deployGiftoken);
    const { erc20, erc20owner } = await loadFixture(deployErc20)

    const myAddress = '0x90C10F9abb753cA860F3BF3D67C9b8d23deB9044'
    const uniAddress = '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984'

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [myAddress],
    });
    const me = await ethers.getSigner(myAddress);

    const uniContractFactory = await ethers.getContractFactory('ERC20')
    const uniContract = uniContractFactory.attach(uniAddress);

    const uniContribution = ethers.utils.parseEther('1')
    const newErc20contribution = 10

    // mint NFT
    await gifttoken.connect(org).mint(ben.address, 1000, 'http://test.com');

    // add native coins
    await gifttoken.connect(gifter).acceptPayment(1000, hre.ethers.constants.AddressZero, 0, {value: 1000});

    // add new erc20 coins
    await erc20.connect(erc20owner).approve(gifttoken.address, newErc20contribution)
    await gifttoken.connect(erc20owner).acceptPayment(1000, erc20.address, newErc20contribution);

    // approve and add real erc20
    await uniContract.connect(me).approve(gifttoken.address, uniContribution);

    // @ts-ignore
    await expect(gifttoken.connect(me).acceptPayment(1000, uniAddress, uniContribution)).changeTokenBalance(
      uniContract, me, uniContribution.mul(-1),
    )

    // show contributions after adding
    console.log('contributions after everything is added', await gifttoken.getContributions(1000));

    // claim native
    // @ts-ignore
    await gifttoken.connect(ben).claimFunds(1000, hre.ethers.constants.AddressZero, gifter.address)    

    // claim new erc20
    // @ts-ignore
    await expect(gifttoken.connect(ben).claimFunds(1000, erc20.address, erc20owner.address)).changeTokenBalance(
      erc20, ben, newErc20contribution
    )

    // claim real erc20 coins
    // @ts-ignore
    await expect(gifttoken.connect(ben).claimFunds(1000, uniAddress, me.address)).changeTokenBalance(
      uniContract, ben, uniContribution
    )

    // show contributions after everything is claimed
    console.log('contributions after everything is claimed', await gifttoken.getContributions(1000));

    // //claim nft
    await gifttoken.connect(ben).claimNFT(1000);

    // //nft owner
    console.log('nft owner: ', await gifttoken.connect(ben).ownerOf(1000));

    // //balanceOf erc20
    console.log('erc20 balance: ', ethers.utils.formatEther(await uniContract.balanceOf(me.address)));

  })

 })