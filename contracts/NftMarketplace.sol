// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol" ;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol" ;

error NftMarketplace__PriceMustBeAboveZero();
error NftMarketplace__NotApprovedForMarketplace() ;
error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
error NftMarketplace__NotOwner() ;
error NftMarketplace__NotListed(address nftAddress, uint256 tokenId) ;
error NftMarketplace__PriceNotMet(address nftAddress, uint256 tokenId, uint256 price) ;
error NftMarketplace__NoProceeds();
error NftMarketplace__TransferFailed ();


// we are coding the state change before we transfer anything 
// we send the nft last 


contract NftMarketplace is ReentrancyGuard {
    // NFT Contract Address ->  NFT Token ID -> Listing/price
    mapping(address =>  mapping( uint256  => Listing))  private s_listings;



    //we want to keep track of how much money people have 

    // seller address -> amount earned 
    mapping(address => uint256) private s_proceeds;

    ////////////////////////
    // Modifier           //  they are used for automatically checking a coxndition prior to executing a function
    /////////////////////////

  





    // we could create 2 mappings: seller and price

    //////////////////////
    //  Main FUnctions  //  
    //////////////////////

    struct Listing{
        uint256 price;
        address seller;


    }//msg.sender is seller

    event ItemListed(

        address indexed seller,
        address indexed nftAddress,
        uint256  indexed tokenId,
        uint256  price
        

    );

    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256  price




    );


    event ItemCancelled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
        
    );
//listing seller address  and price 
      modifier notListed(address nftAddress, uint256 tokenId, address owner){

        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0){
            revert NftMarketplace__AlreadyListed(nftAddress, tokenId);




        }
        _;
    }
        modifier isOwner(address nftAddress, uint256 tokenId, address spender){
            IERC721 nft = IERC721 (nftAddress);
            address owner = nft.ownerOf(tokenId);
            if (spender != owner) {
                revert NftMarketplace__NotOwner();
            }
            _;

        }

        modifier isListed(address nftAddress, uint256 tokenId){
            Listing memory listing = s_listings[nftAddress][tokenId];
            if (listing.price <= 0){
                revert NftMarketplace__NotListed(nftAddress, tokenId);
            }
            _;
        }  




    /*
    * @notice Method for listing your nfr on the market place
     @param nftAddress: address of the nft      
     @param tokenId: the token Id of the nft
     @patam price: sale price of the listed NFt
     @dev, techncially, we could have the contract be the escrow for the nft 
     but this way people can stilll hold their NFTs when listed 
    *
    * *
    * 
    * 
    * 
    * 
    * 
    * 
    * 
    * 
    * /
    */ 
   



    function listItem(address nftAddress, uint256 tokenId, uint256 price) 
    external  //checks to see if the tohe nft is not listed and is the right owner
    notListed(nftAddress, tokenId, msg.sender)
    isOwner(nftAddress, tokenId, msg.sender)

    // challenge: have this contract accept payment in A SUBSET OF tokens as well
    // hint: use chainlink Price feeds to convert the price of tokens between  each other


    
    {
        

        if (price <= 0){
            revert NftMarketplace__PriceMustBeAboveZero(); // the price has to be above 0

        }
        IERC721 nft = IERC721(nftAddress); //we are passing this nft address to this interface

        if (nft.getApproved(tokenId)!= address(this)){ //"this" object refers to "nft" 
            revert NftMarketplace__NotApprovedForMarketplace();
        }
        // 1. send the nft to the contract -- > hold the nft by the contract. Gas expensive
        //2. Owners can still hold their NFT, and give them maerketplace approval
        // tp sell the nft for  them  once the price is met 
// the sender is the one listing the item 
// nft address at the token id 
    // we are mapping the nft address and token id's to the price and sender/seller
    // arry or mapping: you need to map the nft to the owner


        s_listings[nftAddress][tokenId] = Listing(price, msg.sender) ; // the address of the NFT at the token id

        emit ItemListed(msg.sender, nftAddress, price, tokenId);


    // if it an array, we will have to traverse through the array, make it  massive and dynamic
    
    }

    function buyItem(address nftAddress, uint256 tokenId) 
    external 
    payable
    nonReentrant
    isListed( nftAddress,  tokenId)
    {
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if (msg.value < listedItem.price){

            revert NftMarketplace__PriceNotMet(nftAddress, tokenId, listedItem.price) ; //we dont have enough eth to buy the nft
        }

        // we don't  just send the seller  the money....? 
        // we don't send the money to the user ...XXXXXXXXX
        // We have them withdraw the money
        // we want th shift the risk of working with money to the actualy user
        s_proceeds[listedItem.seller] = s_proceeds[listedItem.seller] + msg.value ; //this is the listed item + how much the buyer was willing to pay for it
    //so once we buy this item, we want to delete this from our listing 
        delete(s_listings[nftAddress][tokenId]); //this is how we remove the mapping 
        IERC721(nftAddress).transferFrom(listedItem.seller, msg.sender, tokenId);

        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);

        // check to make sure the nft was transfered 


    }

        //check if buy item is listed

    function cancelListing(address nftAddress, uint256 tokenId) external isOwner( nftAddress, tokenId, msg.sender) isListed( nftAddress, tokenId){

        delete s_listings[nftAddress][tokenId];
        emit ItemCancelled(msg.sender, nftAddress, tokenId);

    }

    function updateListing(address nftAddress, uint256 tokenId, uint256 newPrice)
    external isListed(nftAddress, tokenId) isOwner(nftAddress, tokenId, msg.sender){

        if (newPrice <=0){
            revert NftMarketplace__PriceMustBeAboveZero();


        }

        s_listings[nftAddress][tokenId].price = newPrice; 
        emit ItemListed(msg.sender, nftAddress,  tokenId, newPrice); //because we are relisting it with a new price
    }

    function withdrawProceeds() external{

        uint256 proceeds =  s_proceeds[msg.sender];
        if (proceeds <= 0) {
            revert NftMarketplace__NoProceeds();
        }

        s_proceeds[msg.sender] = 0 ; // we are going to reset the proceeds to  0 zero before we send any proceeds
        (bool success, ) = payable (msg.sender).call{value: proceeds}("") ;
        if(!success){
            revert NftMarketplace__TransferFailed();
        }
    }


        ////////////////////////
    // getter function           //  
    ////////////////////////

        function getListing(address nftAddress, uint256 tokenId) 
            external 
            view 
            returns (Listing memory)
        {

            return s_listings[nftAddress][tokenId];
        }

        function getProceeds(address seller) external view returns(uint256){

            return s_proceeds[seller] ; //the mapping from the sellers address to the proceeds 
        }


    }






    



    






//you do all your state changes first before you call an external contract

/// the safe transfer from checks wehtehr the recpient is a valid erc721 receiver contra t.
// functions checks if `_to` is a smart contract
    

    // 1. `listItem` : list NFTs on the marketplace
    // 2. `buyItem` : buy the NFTs
    // 3. `cancelItem` : Cancel a listing
    // 4. `updateList` : Update Price
    // 5. `withdrawProceeds` : withdrawl payment for my bought NFTs





























