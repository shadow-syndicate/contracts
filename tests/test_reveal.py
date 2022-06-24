import logging
import time
from brownie import Wei, reverts

LOGGER = logging.getLogger(__name__)

def test_reveal_happy_path(accounts, chain, GenesisMintDebug, roach_nft, reveal):
    buyer = accounts[1]
    stage1time = round(time.time()) - 10
    stage1duration = 50
    genesis_sale = accounts[0].deploy(GenesisMintDebug, roach_nft, stage1time, stage1duration, 10_000)
    roach_nft.addOperator(genesis_sale)

    assert roach_nft.balanceOf(buyer) == 0

    genesis_sale.mintStage1noSig(5, 5, 0, 0, "", {'from':buyer, 'amount': 5})

    assert roach_nft.balanceOf(buyer) == 5, "balance after mint is 5"

    tokens = roach_nft.getUsersTokens(buyer)
    assert tokens == [1,2,3,4,5], "getUsersTokens"

    token = roach_nft.tokenOfOwnerByIndex(buyer, 2)
    assert token == 3, "tokenOfOwnerByIndex"

    r = roach_nft.getRoach(1)

    assert r[0] == "0x0", 'genome not set'
    assert r[1] == [0, 0], 'parents'
    # assert abs(r[2] - round(chain.time())) < 5, 'creationTime'
    assert r[3] == 0, 'revealTime'
    assert r[4] == 0, 'generation'
    assert r[5] == 10000, 'resistance'


    chain.sleep(7*24*60*60 + 1) # wait 1 week
    chain.mine()

    assert roach_nft.canReveal(1) == True, "canReveal"
    assert roach_nft.isRevealed(1) == False

    tx = reveal.reveal(1, "0x1234", "0x123", 27, "0x0", "0x0", {'from':buyer})
    e = tx.events[0]
    assert e.name == 'Reveal', 'missing event Reveal'
    assert e['tokenId'] == 1, e

    assert roach_nft.isRevealed(1) == True

    r2 = roach_nft.getRoach(1)
    assert r2[0] == "0x1234", 'genome is set'
    assert r2[1] == [0, 0], 'parents'
    assert r[2] == r2[2], 'creationTime'
    assert abs(r2[3] - round(chain.time())) < 5, 'revealTime'
    assert r2[4] == 0, 'generation'
    assert r2[5] == 10000, 'resistance'

    with reverts("Wrong egg owner"):
        reveal.reveal(2, "0x1234", "0x123", 27, "0x0", "0x0", {'from':accounts[2]})


def test_set_signer(accounts, reveal):
    assert reveal.signerAddress() == accounts[0], "default signer"
    reveal.setSigner(accounts[2])
    assert reveal.signerAddress() == accounts[2], "new signer"
