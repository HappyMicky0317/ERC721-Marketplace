// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Marketplace is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private auctionIds;

    //        ----------- Var --------
    uint256 public platformFees; // percentage (%)
    address payable platFormAddress; //  The address where the money will go
    mapping(uint256 => NftProduct) private IdToProduct; // get the product using Id
    mapping(uint256 => Auction) IdToAuction;
    mapping(address => uint256) BidersBalances; // balance of each bidder

    constructor() {
        platFormAddress = payable(msg.sender);
    }

    // Auction struct

    struct Auction {
        uint256 id;
        bool start;
        bool end;
        uint256 endAt;
        address payable highestBidder;
        uint256 highestBid;
        address payable seller;
        uint256 nftId;
        address nftAddress;
    }

    // Nft struct
    struct NftProduct {
        uint256 id;
        uint256 tokenId;
        address payable owner;
        uint256 price;
        bool sold;
        address nft_contract;
    }

    // ----------- Events-----------
    event ItemIsOnSale(
        uint256 indexed productId,
        uint256 indexed nftId,
        address indexed nftContractAddress,
        uint256 price,
        address seller
    );
    event ItemsSold(
        uint256 indexed productId,
        uint256 indexed nftId,
        address indexed nftContractAddress,
        uint256 price,
        address buyer
    );
    event AuctionCreated(
        uint256 indexed acutionId,
        uint256 indexed nftId,
        address indexed seller,
        address nftAddress,
        uint256 endAt,
        uint256 price
    );
    event Bid(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 indexed nftId,
        uint256 bid
    );
    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 indexed nftId,
        uint256 price
    );

    // put Product to sell = >
    // require price >0

    function putProductToSell(
        uint256 _NftId,
        uint256 _price,
        address _nftContractAddress
    ) public payable nonReentrant {
        require(_price > 0, "you can't sell it at this price ");

        uint256 pricePlusFees = _price + (_price / 100) * 1;

        _tokenIds.increment();
        uint256 productId = _tokenIds.current();
        IdToProduct[productId] = NftProduct(
            productId,
            _NftId,
            payable(msg.sender),
            pricePlusFees,
            false,
            _nftContractAddress
        );

        IERC721(_nftContractAddress).transferFrom(
            msg.sender,
            address(this),
            _NftId
        );
        emit ItemIsOnSale(
            productId,
            _NftId,
            _nftContractAddress,
            pricePlusFees,
            msg.sender
        );
    }

    // ------------ Normal Buy Method -----------
    // require msg.value > price
    // product still availaibe

    function purchaseProduct(uint256 _productId, address _nftContractAddress)
        public
        payable
        nonReentrant
    {
        uint256 product_price = IdToProduct[_productId].price;
        bool isSold = IdToProduct[_productId].sold;
        require(
            msg.value >= product_price,
            "please submit the right amount to purchase"
        );
        require(isSold == false, "Sold out");
        uint256 seller_share = msg.value - ((msg.value * 1) / 100);
        address seller = payable(IdToProduct[_productId].owner);
        uint256 tokenId = IdToProduct[_productId].tokenId;

        // Paiement

        (bool sent, ) = seller.call{value: seller_share}("");
        require(sent, "failed to pay seller");
        (bool sent2, ) = platFormAddress.call{
            value: (msg.value - seller_share)
        }("");
        require(sent2, "failed to pay platform");
        IdToProduct[_productId].sold = true;
        IdToProduct[_productId].owner = payable(msg.sender);

        // transfer NFT
        IERC721(_nftContractAddress).transferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        emit ItemsSold(
            _productId,
            tokenId,
            _nftContractAddress,
            seller_share,
            msg.sender
        );
    }

    // ------------ Get all user Products ----------
    function getMyNFTs() public view returns (NftProduct[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (IdToProduct[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        NftProduct[] memory items = new NftProduct[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (IdToProduct[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                NftProduct storage currentItem = IdToProduct[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    // get all sold items

    function getSoldProducts() public view returns (NftProduct[] memory) {
        uint256 totalProduct = _tokenIds.current();
        uint256 soldItemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalProduct; i++) {
            if (IdToProduct[i + 1].sold == true) {
                soldItemCount += 1;
            }
        }

        NftProduct[] memory products = new NftProduct[](soldItemCount);

        for (uint256 i = 0; i < totalProduct; i++) {
            if (IdToProduct[i + 1].sold == true) {
                NftProduct storage product = IdToProduct[i + 1];
                products[currentIndex] = product;
                currentIndex += 1;
            }
        }
        return products;
    }

    //            ------- get all unsold product (home)---------
    function getUnSoldProducts() public view returns (NftProduct[] memory) {
        uint256 totalProduct = _tokenIds.current();
        uint256 soldItemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalProduct; i++) {
            if (IdToProduct[i + 1].sold == false) {
                soldItemCount += 1;
            }
        }

        NftProduct[] memory products = new NftProduct[](soldItemCount);

        for (uint256 i = 0; i < totalProduct; i++) {
            if (IdToProduct[i + 1].sold == false) {
                NftProduct storage product = IdToProduct[i + 1];
                products[currentIndex] = product;
                currentIndex += 1;
            }
        }
        return products;
    }

    // get a detail about a product :

    function getProductDetails(uint256 _productId)
        public
        view
        returns (NftProduct memory)
    {
        return IdToProduct[_productId];
    }

    // ----------------------- ENGLISH AUCTION--------------------

    // create the auction => first check if this nft not already in an other auction

    function isThisNftAlreadyInAuction(uint256 _nftId, address _nftAddress)
        public
        view
        returns (bool)
    {
        uint256 totalAuctions = auctionIds.current();
        // loop throw all auctions started + has the same nft address
        for (uint256 i = 0; i < totalAuctions; i++) {
            if (
                IdToAuction[i + 1].start == true &&
                IdToAuction[i + 1].nftAddress == _nftAddress
            ) {
                if (IdToAuction[i + 1].nftId == _nftId) {
                    return true;
                }
            }
        }
        return false;
    }

    function createAuction(
        uint256 _nftId,
        address _nftAddress,
        uint256 _endAt,
        uint256 _firstBid
    ) public {
        require(
            isThisNftAlreadyInAuction(_nftId, _nftAddress) == false,
            "this Nft already in aution"
        );
        require(_firstBid > 0, "you can't start at 0 ");

        auctionIds.increment();
        uint256 currentBidId = auctionIds.current();
        IdToAuction[currentBidId] = Auction(
            currentBidId,
            true,
            false,
            _endAt,
            payable(msg.sender),
            _firstBid,
            payable(msg.sender),
            _nftId,
            _nftAddress
        );
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _nftId);
        emit AuctionCreated(
            currentBidId,
            _nftId,
            msg.sender,
            _nftAddress,
            _endAt,
            _firstBid
        );
    }

    // enter to auction

    function bid(uint256 _auctionId) public payable nonReentrant {
        uint256 highest_bid = IdToAuction[_auctionId].highestBid;
        bool isStarted = IdToAuction[_auctionId].start;
        bool isEnded = IdToAuction[_auctionId].end;

        require(msg.value > highest_bid, "value < highest bid");
        require(isStarted, "not started");
        require(isEnded == false, "ended");

        BidersBalances[msg.sender] += msg.value;
        uint256 nftId = IdToAuction[_auctionId].nftId;
        IdToAuction[_auctionId].highestBid = msg.value;
        IdToAuction[_auctionId].highestBidder = payable(msg.sender);
        emit Bid(_auctionId, msg.sender, nftId, msg.value);
    }

    // end the auction everyone can call this function require timeend

    function endAuction(uint256 _auctionId) public nonReentrant {
        uint256 endTime = IdToAuction[_auctionId].endAt;
        bool isStarted = IdToAuction[_auctionId].start;
        bool isEnded = IdToAuction[_auctionId].end;
        require(block.timestamp >=  timestamp + endTime, "not yet");
        require(isStarted == true, "not started");
        require(isEnded == false, "ended");
        address payable highestBidder = IdToAuction[_auctionId].highestBidder;
        BidersBalances[highestBidder] = 0;
        address payable seller = IdToAuction[_auctionId].seller;
        uint256 highest_bid = IdToAuction[_auctionId].highestBid;
        uint256 auctionFee = highest_bid - (highest_bid * 1) / 100;
        address nftAddress = IdToAuction[_auctionId].nftAddress;
        uint256 nftId = IdToAuction[_auctionId].nftId;
        IdToAuction[_auctionId].end = true;
        IdToAuction[_auctionId].start = false;

        ERC721(nftAddress).transferFrom(address(this), highestBidder, nftId);
        (bool sent1, ) = seller.call{value: (highest_bid - auctionFee)}("");
        require(sent1, "failed to send");
        (bool sent2, ) = platFormAddress.call{value: auctionFee}("");
        require(sent2, "failed to send");
        emit AuctionEnded(_auctionId, highestBidder, nftId, highest_bid);
    }

    // withdraw bids but the highest bidder can withdraw only diffrent between
    // his total bids and the highest bid 
    // example : highestBidder_allowed_bids = totalbids - highet_bid_of_the_auction

    function withdrawBids(uint _auctionId) public nonReentrant{
        address highestBidder = IdToAuction[_auctionId].highestBidder;
        uint highestBid = IdToAuction[_auctionId].highestBid;

        uint allowedwithraw ;
        if(msg.sender == highestBidder){
            allowedwithraw = BidersBalances[msg.sender] - highestBid;
            BidersBalances[msg.sender] = highestBid;
        }
        else {
            allowedwithraw = BidersBalances[msg.sender];
            BidersBalances[msg.sender]=0;
        }
        
        (bool sent,) = payable(msg.sender).call{value:allowedwithraw}("");
        require(sent,"failed to send");
    }

    // get details about an auction

    function getAuctionOverview(uint256 _auctionId)
        public
        view
        returns (Auction memory)
    {
        return IdToAuction[_auctionId];
    }
}
// struct Auction{
//         uint id ;
//         bool start;
//         bool end;
//         uint endAt;
//         address highestBidder;
//         uint highestBid;
//         address payable seller;
//         uint nftId;
//         address nftAddress;

//     }
