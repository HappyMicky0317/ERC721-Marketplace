from unittest.mock import create_autospec
from venv import create
from brownie import FreeNFT,Marketplace,interface
from eth_utils import from_wei
from scripts.global_helpful_script import get_account
from scripts.deploy import deployMarketplace
from web3 import Web3



price = Web3.toWei(1,"ether")
account = get_account()
account2 = get_account(2)
second_account =get_account(2)
# minting NFt 
def mintNft():
    deployMarketplace()
    free_nft_contract = FreeNFT[-1]
    print("minting new nft")
    mint = free_nft_contract.awardItem("uri.com",{"from":account})
    mint.wait(1)
    print("new nft minted")


# put item to sell ( nft )

def putProductToSale():
    nft_contract = FreeNFT[-1]
    marketplace_contract = Marketplace[-1]
    tokenId = 1
    # before we put to sell we need to get approved from user to spend his tokens
    approve = interface.IERC721(nft_contract.address).approve(marketplace_contract.address,tokenId,{"from":second_account})
    approve.wait(1)
    putToSellTx = marketplace_contract.putProductToSell(tokenId,price,nft_contract.address,{"from":second_account})
    putToSellTx.wait(1)
    productId = putToSellTx.events["ItemIsOnSale"]["productId"]
    nftId = putToSellTx.events["ItemIsOnSale"]["nftId"]
    nftContractAddress = putToSellTx.events["ItemIsOnSale"]["nftContractAddress"]
    ProductPrice = putToSellTx.events["ItemIsOnSale"]["price"]
    seller = putToSellTx.events["ItemIsOnSale"]["seller"]
    print(f"Product {productId} || Seller:{seller} want to sell NFT:  {nftId} , Price :{Web3.fromWei(ProductPrice,'ether')} from NFT collecte {nftContractAddress}")



    # -------------- Purchase -----------


def purchaseItem():
    nft_contract = FreeNFT[-1]
    marketplace_contract = Marketplace[-1]
    tokenId = 1
    purchaseTx = marketplace_contract.purchaseProduct(tokenId,nft_contract.address,{"from":second_account,"value":price+(price * 0.05)})
    purchaseTx.wait(1)
    productId = purchaseTx.events["ItemsSold"]["productId"]
    nftId = purchaseTx.events["ItemsSold"]["nftId"]
    nftContractAddress = purchaseTx.events["ItemsSold"]["nftContractAddress"]
    productPrice = purchaseTx.events["ItemsSold"]["price"]
    buyer = purchaseTx.events["ItemsSold"]["buyer"]
    print(f"Product {productId} | Buyer :{buyer} buy Nft Id {nftId} for price : {Web3.fromWei(productPrice,'ether')} from collection {nftContractAddress}")

    
# --------- get all product Sold in this platform -------

def getSoldProducts():
    marketplace_contract = Marketplace[-1]
    get_id = marketplace_contract.getSoldProducts()[0][1] # get first product id 
    print(get_id)
    return get_id


# --------- Home : unsold product
def getUnSoldProducts():
    marketplace_contract = Marketplace[-1]
    get_all = marketplace_contract.getUnSoldProducts()
    print(get_all)


# -------------- get product details ------

def getProducOverview():
    marketplace_contract = Marketplace[-1]
    productid = getSoldProducts()
    product = marketplace_contract.getProductDetails(productid)
    print(product)

#- ------------ get all user products -------

def get_user_product():
    marketplace_contract = Marketplace[-1]
    products = marketplace_contract.getMyNFTs({"from":account})
    print(products)


# ----------------- create auction -----------

def createAuction():
    print("creating auction")
    nft_contract = FreeNFT[-1]
    marketplace_contract = Marketplace[-1]
    tokenId = 1
    first_bid = Web3.toWei(2,"ether")
    approve = interface.IERC721(nft_contract.address).approve(marketplace_contract.address,tokenId,{"from":account})
    approve.wait(1)
    create_auction = marketplace_contract.createAuction(
        tokenId,nft_contract.address,86400,first_bid,{"from":account}
    )
    create_auction.wait(1)
    auction_id = create_auction.events["AuctionCreated"]["acutionId"]
    nftId = create_auction.events["AuctionCreated"]["nftId"]
    seller = create_auction.events["AuctionCreated"]["seller"]
    nftAddress = create_auction.events["AuctionCreated"]["nftAddress"]
    endAt = create_auction.events["AuctionCreated"]["endAt"]
    price = create_auction.events["AuctionCreated"]["price"]
    print(f"Auction id : {auction_id}| nft Id: {nftId}| seller : {seller} | nft_address :{nftAddress} | end At : {endAt} | price : {price}")


# -------------- Auction started let's bid ----------

def bid():
    marketplace_contract = Marketplace[-1]
    auction_id_ = 1
    price = Web3.toWei(3,"ether")
    bid = marketplace_contract.bid(auction_id_,{"from":second_account,"value":price})
    bid.wait(1)
    #     event Bid(uint indexed auctionId, address indexed bidder, uint indexed nftId, uint bid);
    auction_id = bid.events["Bid"]["auctionId"]
    bidder = bid.events["Bid"]["bidder"]
    nftId = bid.events["Bid"]["nftId"]
    bid_price = bid.events["Bid"]["bid"]
    print(f"auction_id : {auction_id} |bidder: {bidder} | nftId :{nftId} | bid_price : {bid_price}")

# ----------- End Auction --------------

def endAuction():
    marketplace_contract = Marketplace[-1]
    auction_id_ = 1
    end_auction = marketplace_contract.endAuction(auction_id_,{"from":account})
    end_auction.wait(1)
    auction_id  = end_auction.events["AuctionEnded"]["auctionId"]
    bidder  = end_auction.events["AuctionEnded"]["bidder"]
    nftId  = end_auction.events["AuctionEnded"]["nftId"]
    price  = end_auction.events["AuctionEnded"]["price"]

    print(f"auction :{auction_id} end ! for the nft id {nftId} | the winner {bidder} highest price : {price}")


    # ------------------- BIG IMPORTANT -------------

    """
        Some of functions a test using remix you can do the same.
    """
def main():
    mintNft()
    #putProductToSale()
    #purchaseItem()
    #getSoldProducts()
    #getProducOverview()
    #getUnSoldProducts()
    createAuction()
    bid()
    endAuction()