import os
import logging
from brownie import *
LOGGER = logging.getLogger(__name__)

PUBLISH_SOURCES=True

private_key=os.getenv('DEPLOYER_PRIVATE_KEY')
accounts.add(private_key)

def main():
    print('Deployer account= {}'.format(accounts[0]))

    roach = '0xD0029433F7FCc2b4B6318057eb82afbd1ab3F7b4'
    mutagen = '0x518E0F95C96Ece6AE55699962f013741E03EEF40'
    rrc = '0x3fAb14aEeD6B38Ab4b1E4Ae53a40b57Dd4359C4E'

    mutagenToken = Mutagen.at(mutagen)
    rrcToken = RRC.at(rrc)
    roach_contract = RoachNFT.at(roach)


    config = Config.deploy(mutagenToken, rrcToken, {'from':accounts[0]}, publish_source=PUBLISH_SOURCES)
    geneMixer = GeneMixer.deploy(roach_contract, {'from':accounts[0]}, publish_source=PUBLISH_SOURCES)

    incubator = Incubator.deploy(roach_contract, geneMixer, config, mutagenToken, rrcToken,
                                 {'from':accounts[0]}, publish_source=PUBLISH_SOURCES)

    roach_contract.addOperator(incubator, {'from':accounts[0], "required_confs": 0})

    users = []

    for u in users:
        rrcToken.mint(u, Wei("10000 ether"), {'from':accounts[0], "required_confs": 0})
        mutagenToken.mint(u, Wei("10000 ether"), {'from':accounts[0], "required_confs": 0})
