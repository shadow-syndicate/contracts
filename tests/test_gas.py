import logging
import time
from brownie import Wei, reverts

LOGGER = logging.getLogger(__name__)

def test_gas(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    stage1time = round(time.time()) - 10
    stage1duration = 5
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, stage1time, stage1duration, 1, 10_000)
    roach_nft.addOperator(genesis_sale)

    tx = genesis_sale.mintStage2(10, "", {'from':buyer, 'amount': 10})
    # assert tx.info() == 0

    # 10 roaches
    # 417368 - default OpenZepplin
    # 174062 - ERC721A
    # 137932 - max optimized

