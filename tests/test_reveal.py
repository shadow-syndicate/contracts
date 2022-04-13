import logging
import time
from brownie import Wei, reverts

LOGGER = logging.getLogger(__name__)

def test_reveal(accounts, chain, GenesisSale, weth, roach_nft):
    buyer = accounts[1]
    stage1time = round(time.time()) - 10
    stage1duration = 5
    genesis_sale = accounts[0].deploy(GenesisSale, weth, roach_nft, stage1time, stage1duration, 1, 10_000)
    roach_nft.addOperator(genesis_sale)

    assert roach_nft.balanceOf(buyer) == 0

    weth.transfer(buyer, 1e18)
    weth.approve(genesis_sale, 1e18, {'from':buyer})
    genesis_sale.mint(5, "", {'from':buyer})
    assert roach_nft.balanceOf(buyer) == 5, "balance after mint is 5"

    tokens = roach_nft.getUsersTokens(buyer)
    assert tokens == [1,2,3,4,5], "getUsersTokens"

    assert roach_nft.canReveal(1) == False, "canReveal is False because of cooldown"

    with reverts("Not ready for reveal"):
        roach_nft.reveal(1, {'from':buyer})

    roach1a = roach_nft.getRoach(1)
    assert roach1a[0] == "0x", "random is set"

    chain.sleep(7*24*60*60 + 1) # wait 1 week
    chain.mine()

    assert roach_nft.canReveal(1) == True, "canReveal"

    roach_nft.reveal(1, {'from':buyer})

    roach1b = roach_nft.getRoach(1)
    assert roach1b[0] != "0x", "genome is set"
    assert roach1a[0] != roach1b[0], "genome is set"

