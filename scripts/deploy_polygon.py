import os
import time
import logging
import json
from brownie import *
LOGGER = logging.getLogger(__name__)

# https://docs.chain.link/docs/vrf-contracts/
# v2
VRF_COORDINATOR="0x6168499c0cFfCaCD319c818142124B7A15E857ab"
KEY_HASH="0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc"
subscriptionId=2667

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
                                                     VRF_COORDINATOR,
                                                     KEY_HASH,
                                                     subscriptionId,
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
