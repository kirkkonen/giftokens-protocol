import { expect } from "chai";
// import { ethers, network } from "hardhat";
import hre from 'hardhat'
import '@nomiclabs/hardhat-ethers'
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { erc20Abi } from '../abi/erc20Abi.js'


import { Contract, Signer } from "ethers";

describe("Giftokens", function () {

  async function deploy() {
    const [owner, ben, org, gifter] = await hre.ethers.getSigners()
    const Giftokens = await hre.ethers.getContractFactory('contracts/giftokenV4.sol:Giftokens')
    const gifttoken = await Giftokens.deploy()
    await gifttoken.deployed()

    // await network.provider.request({
    //   method: 'hardhat_impersonateAccount',
    //   params: [sender!.address],
    // })

    return { ben, org, gifter, gifttoken }
  }

  it('mints, accepts payment and returns contribution', async function () {
    const { ben, gifter, org, gifttoken } = await loadFixture(deploy);
    await gifttoken.connect(org).mint(ben.address, 1000, 'http://test.com');
    await gifttoken.connect(gifter).acceptPayment(1000, hre.ethers.constants.AddressZero, 0, {value: 1000});
    //await gifttoken.connect(gifter).acceptPayment(1000, hre.ethers.constants.AddressZero, 0, {value: 1000});
    console.log(await gifttoken.getContributions(1000))  
  })

 })