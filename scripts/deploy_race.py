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
    rrc = '0xE38c7E6f6110493854aC76Ad9cDEb62d2456eCaf'
    mutagen = '0x95681034dc5D4a2BAbcAA07c7d1c3Dd838B2Dc60'

    race = Race.deploy(roach, rrc, mutagen,
                               {'from':accounts[0]},
                               publish_source=PUBLISH_SOURCES)

    rrcToken = RRC.at(rrc)
    rrcToken.addOperator(race, {'from':accounts[0], "required_confs": 0})

    mutagenToken = RRC.at(mutagen)
    mutagenToken.addOperator(race, {'from':accounts[0], "required_confs": 0})
