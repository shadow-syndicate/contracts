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

# Rinkeby https://docs.chain.link/docs/vrf-contracts/#rinkeby-testnet
LINK_TOKEN="0x01BE23585060835E02B77ef475b0Cc51aA1e0709"
VRF_COORDINATOR="0x6168499c0cFfCaCD319c818142124B7A15E857ab"
KEY_HASH="0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc"
FEE=0.25*10e18
SALE_TOKEN="0xc778417e063141139fce010982780140aa0cd5ab" # WETH

ROACH_PRICE=1e15
PUBLISH_SOURCES=True

private_key=os.getenv('DEPLOYER_PRIVATE_KEY')
accounts.add(private_key)

def main():
    print('Deployer account= {}'.format(accounts[0]))

    # metadata = Metadata.deploy("https://metadev.roachracingclub.com/roach/", {'from':accounts[0]},
    #     publish_source=PUBLISH_SOURCES
    # )
    # roach_contract = RoachNFT.deploy(metadata, {'from':accounts[0]},
    #     publish_source=PUBLISH_SOURCES
    # )
    # genome_provider = GenomeProvider.deploy(roach_contract,
    #                                   # LINK_TOKEN,
    #                                   # VRF_COORDINATOR,
    #                                   # KEY_HASH,
    #                                   # FEE,
    #                                         {'from':accounts[0]},
    #         publish_source=PUBLISH_SOURCES
    # )
    # roach_contract.setGenomeProviderContract(genome_provider, {'from':accounts[0], "required_confs": 0})

    roach_contract = RoachNFT.at("0x3Ad749b95574b656D200813CaF10FF9aB4E9dB0a")

    genesis_sale = GenesisSaleDebug.deploy(SALE_TOKEN, roach_contract, round(time.time()), 60*60*24, ROACH_PRICE, 10_000,
                                           {'from':accounts[0]},
                                            publish_source=PUBLISH_SOURCES)
    roach_contract.addOperator(genesis_sale, {'from':accounts[0], "required_confs": 0})

    genesis_sale.addOperator("0x19816Aa1Ae9f112f1b0DEd666E9f46807C5a47CF", {'from':accounts[0], "required_confs": 0})
    genesis_sale.addOperator("0xDb65A8D80E185869A555647827E9Df951c5b9b08", {'from':accounts[0], "required_confs": 0})

    genesis_sale.setWhitelistAddress("0x19D6580D0652152370E17E2C48aC85c1249c129D", 50, 15, {'from':accounts[0], "required_confs": 0})
    genesis_sale.setWhitelistAddress("0x19816Aa1Ae9f112f1b0DEd666E9f46807C5a47CF", 35, 25, {'from':accounts[0], "required_confs": 0})
    genesis_sale.setWhitelistAddress("0xDb65A8D80E185869A555647827E9Df951c5b9b08", 35, 25, {'from':accounts[0], "required_confs": 0})
    genesis_sale.setWhitelistAddress("0x11543160A6215172db936161921d70ed1c216306", 35, 25, {'from':accounts[0], "required_confs": 0})
