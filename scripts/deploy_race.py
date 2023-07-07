import os
import logging
from brownie import *
LOGGER = logging.getLogger(__name__)

PUBLISH_SOURCES=True

private_key=os.getenv('DEPLOYER_PRIVATE_KEY')
accounts.add(private_key)

def main():
    print('Deployer account= {}'.format(accounts[0]))

    roach = '0x69ED5E60ee3B91408D578A3527b17Df1372d96B6'
    rrc = '0x74D19B44b651e0b5395B29A2f8fed0D142eCF980'
    mutagen = '0xB9EB8dbB443eF0f7d52bDda018d7AC00ACDB3709'

    race = Race.deploy(roach, rrc, mutagen,
                               {'from':accounts[0]},
                               publish_source=PUBLISH_SOURCES)
