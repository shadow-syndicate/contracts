import os
import time
import logging
import json
from brownie import *
LOGGER = logging.getLogger(__name__)

PUBLISH_SOURCES=True

private_key=os.getenv('DEPLOYER_PRIVATE_KEY')
accounts.add(private_key)

def main():
    print('Deployer account= {}'.format(accounts[0]))

    metadata = Metadata.deploy("https://rrcdevmeta.kindex.lv/meta/roach/v18/",
                               "https://rrcdevmeta.kindex.lv/meta/contract/v18/",
                               {'from':accounts[0]},
                                publish_source=PUBLISH_SOURCES
    )
    roach_contract = RoachNFT.deploy(metadata, {'from':accounts[0]},
        publish_source=PUBLISH_SOURCES
    )

    genesis_sale = GenesisSaleDebug.deploy(roach_contract, round(time.time()), 60*60*24, 10_000,
                                           {'from':accounts[0]},
                                            publish_source=PUBLISH_SOURCES)
    print('genesis_sale = {}'.format(genesis_sale))
    roach_contract.addOperator(genesis_sale, {'from':accounts[0], "required_confs": 0})
    genesis_sale.addOperator("0x549E82b2e4831E3d2bCD6dA4a6eBbBf43692D45b", {'from':accounts[0], "required_confs": 0})

    # reveal_contract = Reveal.deploy(roach_contract, {'from':accounts[0]},
    #                                  publish_source=PUBLISH_SOURCES
    #                                  )
    # roach_contract.addOperator(reveal_contract, {'from':accounts[0], "required_confs": 0})
