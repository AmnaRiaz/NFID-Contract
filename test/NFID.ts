import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { boolean, string } from "hardhat/internal/core/params/argumentTypes";

describe("NFID", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deploy() {

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const NFID = await ethers.getContractFactory("NFID");
    const nfid = await NFID.deploy();

    return { nfid };
  }

  describe("Testing", function () {
    it("mint the nfid", async function () {
      const { nfid } = await loadFixture(deploy);
      var address = "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2";
      await nfid.mint(address, 1234567890123456)

      expect(await nfid.checkNFID(address)).to.equal(true);
    });

    it("burn the nfid", async function () {
      const { nfid } = await loadFixture(deploy);
      var address = "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2";
      await nfid.mint(address, 1234567890123456)
      await nfid.burn(address, 1234567890123456)

      expect(await nfid.checkNFID(address)).to.equal(false);
    });

    it("mint after burn the nfid", async function () {
      const { nfid } = await loadFixture(deploy);
      var address = "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2";
      await nfid.mint(address, 1234567890123456)
      await nfid.burn(address, 1234567890123456)

      expect(await nfid.checkNFID(address)).to.equal(false);

      await nfid.mint(address, 1234567890123456)

      expect(await nfid.checkNFID(address)).to.equal(true);
    });

    it("mint with second account", async function () {
      const { nfid } = await loadFixture(deploy);
      var address = "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db";
      await nfid.mint(address, 1234567890654321)

      expect(await nfid.checkNFID(address)).to.equal(true);
    });

    it("checks If the address and NFID are accociated with eachother", async function() {
      const { nfid } = await loadFixture(deploy);
      var address = "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2";
      // await nfid.addressAssociatedNFID(address, 1234567890123456 )
      expect(await nfid.addressAssociatedNFID(address,1234567890123456)).to.be.false;
    });


    it("checks If the address has the NFID", async function() {
      const { nfid } = await loadFixture(deploy);
      var address = "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2";
      // await nfid.findNFID(address)
      expect(await nfid.findNFID(address)).to.equal(0);
    })

    

  });
});
