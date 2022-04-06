import os
import time
import logging
from brownie import *
LOGGER = logging.getLogger(__name__)

# Mumbai
LINK_TOKEN="0x326C977E6efc84E512bB9C30f76E30c160eD06FB"
VRF_COORDINATOR="0x8C7382F9D8f56b33781fE506E897a4F1e2d17255"
KEY_HASH="0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4"
FEE=0.0001*10e18
SALE_TOKEN="0xa6fa4fb5f76172d178d61b04b0ecd319c5d1c0aa" # WETH

# # Rinkeby https://docs.chain.link/docs/vrf-contracts/#rinkeby-testnet
LINK_TOKEN="0x01BE23585060835E02B77ef475b0Cc51aA1e0709"
VRF_COORDINATOR="0x6168499c0cFfCaCD319c818142124B7A15E857ab"
KEY_HASH="0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc"
FEE=0.25*10e18
SALE_TOKEN="0xc778417e063141139fce010982780140aa0cd5ab" # WETH
#
# # Kovan
# LINK_TOKEN="0xa36085f69e2889c224210f603d836748e7dc0088"
# VRF_COORDINATOR=""
# KEY_HASH=""
# FEE=0.25*10e18
# SALE_TOKEN="0xd0a1e359811322d97991e03f863a0c30c2cf029c" # WETH

ROACH_PRICE=1e14
PUBLISH_SOURCES=True

private_key=os.getenv('DEPLOYER_PRIVATE_KEY')
accounts.add(private_key)

def main():
    print('Deployer account= {}'.format(accounts[0]))

    metadata = Metadata.deploy("https://rrcdevmeta.kindex.lv/meta/roach/v7/", {'from':accounts[0]},
        publish_source=PUBLISH_SOURCES
    )
    roach_contract = RoachNFT.deploy(metadata, {'from':accounts[0]},
        publish_source=PUBLISH_SOURCES
    )
    genome_provider = GenomeProvider.deploy(roach_contract,
                                      # LINK_TOKEN,
                                      # VRF_COORDINATOR,
                                      # KEY_HASH,
                                      # FEE,
                                            {'from':accounts[0]},
            publish_source=PUBLISH_SOURCES
    )
    genome_provider.setTraitWeight(1, [1,3,4,1], [5,2,1,1], {'from':accounts[0], "required_confs": 0})
    genome_provider.setTraitWeight(2, [0, 1], [1, 0], {'from':accounts[0], "required_confs": 0})
    genome_provider.setTraitWeight(3, [1, 2, 3], [3,2,1], {'from':accounts[0], "required_confs": 0})
    genome_provider.setTraitWeight(4, [1,2,3,4,5], [1,2,3,4,5], {'from':accounts[0], "required_confs": 0})
    genome_provider.setTraitWeight(5, [1], [1], {'from':accounts[0], "required_confs": 0})
    genome_provider.setTraitWeight(6, [100], [100], {'from':accounts[0], "required_confs": 0})

    roach_contract.setGenomeProviderContract(genome_provider, {'from':accounts[0], "required_confs": 0})

    # roach_contract = RoachNFT.at("0x510CC3fB0E685Ff20768298d62b231a1A1df35c6")

    genesis_sale = GenesisSaleDebug.deploy(SALE_TOKEN, roach_contract, round(time.time()), 60*60*24, ROACH_PRICE, 10_000,
                                           {'from':accounts[0]},
                                            publish_source=PUBLISH_SOURCES)
    roach_contract.addOperator(genesis_sale, {'from':accounts[0], "required_confs": 0})

    genesis_sale.addOperator("0x549E82b2e4831E3d2bCD6dA4a6eBbBf43692D45b", {'from':accounts[0], "required_confs": 0})

    genesis_sale.setWhitelistAddress("0x5c8eA699a610B09c5b6bf3dbbE1b2120F9Fd00B6", 5, 15, {'from':accounts[0], "required_confs": 0})
    genesis_sale.setWhitelistAddress("0x549E82b2e4831E3d2bCD6dA4a6eBbBf43692D45b", 5, 25, {'from':accounts[0], "required_confs": 0})
