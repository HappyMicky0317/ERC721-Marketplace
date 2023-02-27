from brownie import FreeNFT,Marketplace
from scripts.global_helpful_script import get_account


account = get_account()


def deployMarketplace():
    deployNft()
    print("deploying marketPlace ..")
    marketplace = Marketplace.deploy({"from":account},publish_source= True)
    print("Done !")


def deployNft():
    print("deploying Nft contract ...")
    nft = FreeNFT.deploy({"from":account},publish_source= True)
    print("Done !")

def main():
    deployMarketplace()
