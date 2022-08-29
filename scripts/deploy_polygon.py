import os
import time
import logging
import json
from brownie import *
LOGGER = logging.getLogger(__name__)

# https://docs.chain.link/docs/vrf-contracts/
# Rinkeby v2
# VRF_COORDINATOR="0x6168499c0cFfCaCD319c818142124B7A15E857ab"
# KEY_HASH="0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc"
# subscriptionId=2667

# # Mumbai v2
# VRF_COORDINATOR="0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed"
# KEY_HASH="0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f"
# subscriptionId=661

# # Goerli v2
# VRF_COORDINATOR="0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D"
# KEY_HASH="0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15"
# subscriptionId=208

# Polygon Mainnet
VRF_COORDINATOR="0xae975071be8f8ee67addbc1a82488f1c24858067"
KEY_HASH="0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93" # 200 Gwei
subscriptionId=271


PUBLISH_SOURCES=False

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

def create_config():
    slots = json.load(open('config/slots.json',))
    trait_type = json.load(open('config/trait_type.json',))
    result = {}
    for slot in slots:
        key = trait_type[slot]
        result[key] = {
            "weight": [],
            "weightMaxBonus": [],
            "data": [],
            "slots": slots[slot]
        }
        for i in range(100):
            for k in range(len(slots[slot])):
                result[key]["data"].append(i)
            result[key]["weight"].append(1)
            result[key]["weightMaxBonus"].append(1)

    print(result)
    return result

def main():
    config = load_config()
    # config = create_config()

    genome_provider = GenomeProviderChainlink.deploy(VRF_COORDINATOR,
                                                     KEY_HASH,
                                                     subscriptionId,
                                                     {'from':accounts[0]},
                                                     publish_source=PUBLISH_SOURCES
                                                     )
    for c in config:
        genome_provider.setTraitConfig(c,
                                       config[c]["slots"],
                                       config[c]["data"],
                                       config[c]["weight"],
                                       config[c]["weightMaxBonus"],
                                       {'from':accounts[0], "required_confs": 0})
