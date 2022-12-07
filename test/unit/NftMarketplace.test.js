const { ethers, network, deployments, getNamedAccounts } = require("hardhat")
const { developmentChains } = require("../../helper-hardhat-config")
const { assert, expect } = require("chai")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Nft MarketPlace Tests", function () {
          let nftMarketplace, basicNft, deployer, player //these are blocked scoped
          const PRICE = ethers.utils.parseEther("0.1")
          const TOKEN_ID = 0
          beforeEach(async function () {
              //these are async executions so we....include/declare them?

              //player = ( await  getNamedAccounts()).player
              const accounts = await ethers.getSigners() // or with get named accounts above
              deployer = accounts[0]

              player = accounts[1]

              await deployments.fixture(["all"]) //deploy all of those  contracts...choose who we  connect to player
              nftMarketplace = await ethers.getContract("NftMarketplace") //get Marketplace contract
              nftMarketplace = nftMarketplace.connect(deployer) //  connect to marketplace contract via deployer account

              basicNft = await ethers.getContract("BasicNft") //player defaulted to the first player
              basicNft = basicNft.connect(deployer) // connect to nft contract via deployer account
              //mint nft
              await basicNft.mintNft() //the deployer is calling mint it and deployer approving it to send it to the market place
              await basicNft.approve(nftMarketplace.address, TOKEN_ID)

              //the market can't call approve b/c it does not own the nft. the deployer has to apprive it
          })
          //player is buying the nft

          it("list and can be bought ", async function () {
              //list nft via deployer acc here
              await nftMarketplace.listItem(basicNft.address, TOKEN_ID, PRICE)
              // connect to marketplace via player account
              nftMarketplace = await nftMarketplace.connect(player) //
              // buy nft
              await nftMarketplace.buyItem(basicNft.address, TOKEN_ID, {
                  value: PRICE,
              })
              const newOwner = await basicNft.ownerOf(TOKEN_ID)
              // get proceedings of deployer
              const deployerProceeds = await nftMarketplace.getProceeds(deployer.address)
              assert(newOwner.toString() == player.address)
              assert(deployerProceeds.toString() == PRICE.toString()) //they should have been paid that price
          })
      })
