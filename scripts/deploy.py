import os
import time
import logging
import json
from brownie import *
LOGGER = logging.getLogger(__name__)

# Mumbai
VRF_COORDINATOR="0x8C7382F9D8f56b33781fE506E897a4F1e2d17255"
KEY_HASH="0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4"
SALE_TOKEN="0xa6fa4fb5f76172d178d61b04b0ecd319c5d1c0aa" # WETH

# # Rinkeby https://docs.chain.link/docs/vrf-contracts/#rinkeby-testnet
VRF_COORDINATOR="0x6168499c0cFfCaCD319c818142124B7A15E857ab"
KEY_HASH="0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc"
SALE_TOKEN="0xc778417e063141139fce010982780140aa0cd5ab" # WETH
VRF_SUBSCRIPTION=2667
VRF_CONFIRMATIONS=3 # 3..200

ROACH_PRICE=1e14
PUBLISH_SOURCES=True

private_key=os.getenv('DEPLOYER_PRIVATE_KEY')
accounts.add(private_key)

def load_config():
    slots = json.load(open('config/slots.json',))
    trait_type = json.load(open('config/trait_type.json',))
    traits = json.load(open('config/traits.json',))

    result = {}
    for t in traits:
        # print(t['type'], slots[t['type']])
        key = trait_type[t['type']]
        if not key in result:
            result[key] = {
                "weight": [],
                "weightMaxBonus": [],
                "data": [],
                "slots": slots[t['type']]
            }
        result[key]["weight"].append(t["weight"])
        result[key]["weightMaxBonus"].append(t["weightMaxBonus"])
        for i in range(len(slots[t['type']])):
            result[key]["data"].append(t["genes"][i])

    print(result)
    return result

def main():
    print('Deployer account= {}'.format(accounts[0]))

    metadata = Metadata.deploy("https://rrcdevmeta.kindex.lv/meta/roach/v10/",
                               "https://rrcdevmeta.kindex.lv/meta/contract/v10/",
                               {'from':accounts[0]},
                                publish_source=PUBLISH_SOURCES
    )
    roach_contract = RoachNFT.deploy(metadata, {'from':accounts[0]},
        publish_source=PUBLISH_SOURCES
    )
    genome_provider = GenomeProviderChainlink.deploy(roach_contract,
                                      VRF_COORDINATOR,
                                      KEY_HASH,
                                      VRF_SUBSCRIPTION,
                                      VRF_CONFIRMATIONS,
                                    {'from':accounts[0]},
            publish_source=PUBLISH_SOURCES
    )
    config = load_config()
    for c in config:
        genome_provider.setTraitConfig(c,
                                       config[c]["slots"],
                                       config[c]["data"],
                                       config[c]["weight"],
                                       config[c]["weightMaxBonus"],
                                       {'from':accounts[0], "required_confs": 0})

    roach_contract.setGenomeProviderContract(genome_provider, {'from':accounts[0], "required_confs": 0})

    # roach_contract = RoachNFT.at("0x510CC3fB0E685Ff20768298d62b231a1A1df35c6")

    genesis_sale = GenesisSaleDebug.deploy(SALE_TOKEN, roach_contract, round(time.time()), 60*60*24, ROACH_PRICE, 10_000,
                                           {'from':accounts[0]},
                                            publish_source=PUBLISH_SOURCES)
    roach_contract.addOperator(genesis_sale, {'from':accounts[0], "required_confs": 0})

    genesis_sale.addOperator("0x549E82b2e4831E3d2bCD6dA4a6eBbBf43692D45b", {'from':accounts[0], "required_confs": 0})

    genesis_sale.setWhitelistAddress("0x5c8eA699a610B09c5b6bf3dbbE1b2120F9Fd00B6", 5, 25, {'from':accounts[0], "required_confs": 0})
    genesis_sale.setWhitelistAddress("0x549E82b2e4831E3d2bCD6dA4a6eBbBf43692D45b", 5, 25, {'from':accounts[0], "required_confs": 0})
