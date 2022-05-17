import logging
import time
from brownie import Wei, reverts, web3

LOGGER = logging.getLogger(__name__)
ZERO_ADDRESS = "0x" + "0" * 40

def test_nft(accounts, chain, roach_nft):
    roach_nft.mint(accounts[1], "0x123456", [1, 2], 12, 534)
    last = roach_nft.lastRoachId()
    r = roach_nft.getRoach(last)

    assert r[0] == "0x123456", 'genome'
    assert r[1] == [1, 2], 'parents'
    assert abs(r[2] - round(chain.time())) < 5, 'creationTime'
    assert r[3] == 0, 'revealTime'
    assert r[4] == 12, 'generation'
    assert r[5] == 534, 'resistance'

    with reverts("query for nonexistent token"):
        r = roach_nft.getRoach(last + 1)

    errMsg = web3.keccak(text='TransferCallerNotOwnerNorApproved()')[:4].hex()
    with reverts("typed error: " + errMsg):
        roach_nft.burn(last, {'from':accounts[2]})

    roach_nft.burn(last, {'from':accounts[1]})

    with reverts("query for nonexistent token"):
        r = roach_nft.getRoach(last)


def test_721a(accounts, roach_nft):
    assert roach_nft.totalSupply() == 0, 'totalSupply'

    with reverts(""): # TODO: correct error message
        r = roach_nft.ownerOf(0)

    roach_nft.mintGen0(accounts[1], 2, 25, "syndicate")

    assert roach_nft.ownerOf(1) == accounts[1]
    assert roach_nft.ownerOf(2) == accounts[1]

    assert roach_nft.totalSupply() == 2, 'totalSupply'
    roach_nft.burn(1, {'from':accounts[1]})

    assert roach_nft.totalSupply() == 1, 'totalSupply'

    with reverts(""): # TODO: correct error message
        r = roach_nft.ownerOf(1)

    with reverts(""): # TODO: correct error message
        r = roach_nft.ownerOf(10)

def test_enum(accounts, roach_nft):
    roach_nft.mintGen0(accounts[1], 3, 25, "syndicate")
    roach_nft.mintGen0(accounts[2], 1, 0, "")
    roach_nft.mintGen0(accounts[1], 2, 25, "syndicate")

    tokens = roach_nft.getUsersTokens(accounts[1])
    assert tokens == [1,2,3,5,6], "getUsersTokens"

    roach_nft.burn(2, {'from':accounts[1]})

    tokens = roach_nft.getUsersTokens(accounts[1])
    assert tokens == [1,3,5,6], "getUsersTokens"

    token = roach_nft.tokenOfOwnerByIndex(accounts[1], 2)
    assert token == 5, "tokenOfOwnerByIndex"
