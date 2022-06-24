import logging
import time
from brownie import Wei, reverts

LOGGER = logging.getLogger(__name__)

def test_gas(accounts, GenesisMintDebug, roach_nft):
    buyer = accounts[1]
    stage1time = round(time.time()) - 10
    stage1duration = 50
    genesis_sale = accounts[0].deploy(GenesisMintDebug, roach_nft, stage1time, stage1duration, 10_000)
    roach_nft.addOperator(genesis_sale)

    tx = genesis_sale.mintStage1noSig(10, 10, 0, 0, "", {'from':buyer, 'amount': 10})
    # assert tx.info() == 0

    # 10 roaches
    # 417368 - default OpenZepplin
    # 174062 - ERC721A
    # 137932 - max optimized

