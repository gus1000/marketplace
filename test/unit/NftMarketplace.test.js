const{ ethers, network, deployments, getNamedAccounts} = require("hardhat")
const{developmentChains} = require("../../helper-hardhat-config")
const {assert, expect} = require("chai")

!developmentChains.includes(network.name)
    ? describe.skip 
    : describe("Nft MarketPlace Tests", function () {
            let nftMarketplace, basicNft, deployer, player //these are blocked scoped
            const PRICE = ethers.utils.parseEther("0.1")
            const TOKEN_ID = 0
            beforeEach(async function() {
                //these are async executions so we....include/declare them?
                deployer = (await getNamedAccounts()).deployer // since we have declared deployer
                //player = ( await  getNamedAccounts()).player
                const accounts = await ethers.getSigners() // or with get named accounts above
                player = accounts[1]
                await deployments.fixture(["all"]) //deploy all of those  contracts...choose who we  connect to player 
                nftMarketplace = await ethers.getContract("NftMarketplace", player) //ethres defaults at grabbing  at  the deployer account at account[0]
                nftMarketplace = await nftMarketplace.connect(player) // we use the player whenever we call a function
                // we want the player to be calling  a function on nftMarketplace , not the deployer 

                basicNft = await ethers.getContract("BasicNft") //player defaulted to the first player 
                await basicNft.mintNft()//the deployer is calling mint it and deployer approving it to send it to the market place
                await basicNft.approve(nftMarketplace.address,  TOKEN_ID)
                //the market can't call approve b/c it does not own the nft. the deployer has to apprive it
            })
//player is buying the nft

            it("list and can be bought ", async function() {
                await nftMarketplace.listItem(basicNft.address, TOKEN_ID, PRICE)
                const playerConnectedNftMarketplace = nftMarketplace.connect(player) //that is how you connect an account
                await playerConnectedNftMarketplace.buyItem(  basicNft.address, TOKEN_ID, { value: PRICE})
                const newOwner =  await basicNft.ownerOf(TOKEN_ID)
                const deployerProceeds = await  nftMarketplace.getProceeds(deployer)
                assert(newOwner.toString() == player.address )
                assert (deployerProceeds.toString() == PRICE.toString())//they should have been paid that price 
            })

        })











    








