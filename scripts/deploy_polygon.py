import os
import time
import logging
import json
from brownie import *
LOGGER = logging.getLogger(__name__)

# Rinkeby https://docs.chain.link/docs/vrf-contracts/#rinkeby-testnet
LINK_TONEN="0x01BE23585060835E02B77ef475b0Cc51aA1e0709"
VRF_COORDINATOR="0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B"
KEY_HASH="0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311"
FEE=0.1e18
SECRET_HASH='0x1234'
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
    genome_provider = GenomeProviderChainlink.deploy(SECRET_HASH,
                                                     LINK_TONEN,
                                                     VRF_COORDINATOR,
                                                     KEY_HASH,
                                                     FEE,
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
