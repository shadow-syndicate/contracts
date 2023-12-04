import os
import time
import logging
import json
from brownie import *
LOGGER = logging.getLogger(__name__)
from brownie.network.gas.strategies import LinearScalingStrategy

PUBLISH_SOURCES=False

private_key=os.getenv('DEPLOYER_PRIVATE_KEY')
accounts.add(private_key)

def main():
    print('Deployer account= {}'.format(accounts[0]))
    gas_strategy = LinearScalingStrategy("2 gwei", "2 gwei", 1.1)

    metadata = Metadata.deploy("https://rrcdevmeta.kindex.lv/meta/roach/v19/",
                               "https://rrcdevmeta.kindex.lv/meta/contract/v19/",
                               {'from':accounts[0], "gas_price": gas_strategy},
                                publish_source=PUBLISH_SOURCES)
    roach_contract = RoachNFT.deploy(metadata, {'from':accounts[0], "gas_price": gas_strategy}, publish_source=PUBLISH_SOURCES)

    unlocker = Unlocker.deploy(roach_contract, {'from':accounts[0], "gas_price": gas_strategy}, publish_source=PUBLISH_SOURCES)
    roach_contract.addOperator(unlocker, {'from':accounts[0], "required_confs": 0})

    ccipRouter = "0xd0daae2231e9cb96b94c8512223533293c3693bf" # Sepolia
    # ccipRouter = "0x70499c328e1e2a3c41108bd3730f6670a44595d1" # Mumbai

    bridge = RoachNftBridge.deploy(roach_contract, ccipRouter, {'from':accounts[0], "gas_price": gas_strategy}, publish_source=PUBLISH_SOURCES)
    roach_contract.addOperator(bridge, {'from':accounts[0], "required_confs": 0})

    genesis_sale = GenesisMintDebug.deploy(roach_contract, round(time.time()), 60*60, 100,
                                            {'from':accounts[0], "gas_price": gas_strategy},
                                             publish_source=PUBLISH_SOURCES)
    print('genesis_sale = {}'.format(genesis_sale))
    roach_contract.addOperator(genesis_sale, {'from':accounts[0], "required_confs": 0, "gas_price": gas_strategy})
    genesis_sale.addOperator("0x549E82b2e4831E3d2bCD6dA4a6eBbBf43692D45b", {'from':accounts[0], "required_confs": 0, "gas_price": gas_strategy})

    reveal_contract = RevealDebug.deploy(roach_contract, {'from':accounts[0]},
                                     publish_source=PUBLISH_SOURCES
                                     )
    roach_contract.addOperator(reveal_contract, {'from':accounts[0], "required_confs": 0})

    reveal_contract.uploadGenomes([
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    ], {'from':accounts[0], "required_confs": 0})

    # rrcToken = RRC.deploy({'from':accounts[0]}, publish_source=PUBLISH_SOURCES)
    # mutagenToken = Mutagen.deploy({'from':accounts[0]}, publish_source=PUBLISH_SOURCES)

    race = Race.deploy(roach_contract, rrcToken, mutagenToken,
                       {'from':accounts[0]},
                       publish_source=PUBLISH_SOURCES)

    # rrcToken.addOperator(race, {'from':accounts[0], "required_confs": 0})
    # mutagenToken.addOperator(race, {'from':accounts[0], "required_confs": 0})
    #
    # config = Config.deploy({'from':accounts[0]}, publish_source=PUBLISH_SOURCES)
    # geneMixer = GeneMixer.deploy(roach_contract, {'from':accounts[0]}, publish_source=PUBLISH_SOURCES)
    #
    # incubator = Incubator.deploy(roach_contract, geneMixer, config, mutagenToken, rrcToken,
    #                              {'from':accounts[0]}, publish_source=PUBLISH_SOURCES)
    #
    # roach_contract.addOperator(incubator, {'from':accounts[0], "required_confs": 0})
