const { network } = require("hardhat")
const { developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")


module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
   

    let  args = []

    const basicnft = await deploy("BasicNft", {

        from: deployer,
        log: true,
        args: args,
        waitBlockConfirmations : network.config.blockConfirmations || 1 ,
    })

    if (!developmentChains.includes(network.name)){
        log('Verify')
        await verify (basicnft.address, args)
    }


}



module.exports.tags = ["all", "basicNft"]
