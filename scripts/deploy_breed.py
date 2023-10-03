import sys
import os
import logging
from brownie import *
LOGGER = logging.getLogger(__name__)

PUBLISH_SOURCES=True

private_key=os.getenv('DEPLOYER_PRIVATE_KEY')
accounts.add(private_key)

def main():
    print('Deployer account= {}'.format(accounts[0]))

    metadata = 'x'
    roach_contract = RoachNFT.at("x")
    incubator = 'x'
    geneMixer = 'x'
    mutagenToken = Mutagen.at('x')
    rrcToken = RRC.at('x')

    roach_contract = RoachNFT.deploy(metadata, {'from':accounts[0]}, publish_source=PUBLISH_SOURCES)

    # reveal_contract = RevealAuto.deploy(roach_contract, {'from':accounts[0]},
    #                                      publish_source=PUBLISH_SOURCES
    #                                   )
    # roach_contract.addOperator(reveal_contract, {'from':accounts[0], "required_confs": 0})


    config = Config.deploy(mutagenToken, rrcToken, {'from':accounts[0]}, publish_source=PUBLISH_SOURCES)
    # geneMixer = GeneMixer.deploy(roach_contract, {'from':accounts[0]}, publish_source=PUBLISH_SOURCES)
    #
    incubator = Incubator.deploy(roach_contract, geneMixer, config, mutagenToken, rrcToken,
                                  {'from':accounts[0]}, publish_source=PUBLISH_SOURCES)
    roach_contract.addOperator(incubator, {'from':accounts[0], "required_confs": 0})

    users = [

    ]

    for u in users:
        # rrcToken.mint(u, Wei("10000 ether"), {'from':accounts[0], "required_confs": 0})
        # mutagenToken.mint(u, Wei("10000 ether"), {'from':accounts[0], "required_confs": 0})
        count = 5

        roach_contract.mintGen0(u, count, 0, 'shadow', {'from':accounts[0], "required_confs": 1})
        tokenId = roach_contract.lastRoachId()
        for t in range(tokenId - count + 1, tokenId):
            roach_contract.revealOperator(t, "", {'from':accounts[0], "required_confs": 0})
