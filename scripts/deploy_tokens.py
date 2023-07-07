import os
import logging
from brownie import *
LOGGER = logging.getLogger(__name__)

PUBLISH_SOURCES=True

private_key=os.getenv('DEPLOYER_PRIVATE_KEY')
accounts.add(private_key)

def main():
    print('Deployer account= {}'.format(accounts[0]))

    rrc = RRC.deploy({'from':accounts[0]}, publish_source=PUBLISH_SOURCES)
    mutagen = Mutagen.deploy({'from':accounts[0]}, publish_source=PUBLISH_SOURCES)
