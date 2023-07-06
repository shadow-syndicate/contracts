import os
import time
import logging
import json
from brownie import *
LOGGER = logging.getLogger(__name__)
from brownie.network.gas.strategies import LinearScalingStrategy

PUBLISH_SOURCES=True

private_key=os.getenv('DEPLOYER_PRIVATE_KEY')
accounts.add(private_key)

def main():
    print('Deployer account= {}'.format(accounts[0]))

    race = Race.deploy("0x69ED5E60ee3B91408D578A3527b17Df1372d96B6",
                               {'from':accounts[0], "nonce": 74},
                               publish_source=PUBLISH_SOURCES)
