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

    # roach_nft.mintWithId(accounts[1], 10010, "0x123456", [1, 2], 0, 0, 12, 11)
    # assert roach_nft.totalSupply() == 2, 'totalSupply'
    # assert roach_nft.ownerOf(10010) == accounts[1], 'ownerOf mintWithId'
    #
    # with reverts(""):
    #     r = roach_nft.ownerOf(10011)
    #
    # # assert roach_nft.ownerOf(9) != accounts[1], 'ownerOf mintWithId-1'
    #
    # with reverts(""):
    #     r = roach_nft.ownerOf(10009)
    #
    # with reverts(""):
    #     r = roach_nft.ownerOf(10003)
    #
    # assert roach_nft.ownerOf(2) == accounts[1], 'keep owner'

    # with reverts("batch region limit"):
    #     roach_nft.mintWithId(accounts[1], 10, "0x123456", [1, 2], 0, 0, 12, 11)
    #
    # roach_nft.mintWithId(accounts[3], 10013, "0x123456", [1, 2], 0, 0, 12, 11)
    # assert roach_nft.totalSupply() == 3, 'totalSupply'
    # assert roach_nft.ownerOf(10013) == accounts[3], 'mintWithId owner'
    # roach_nft.burn(10013, {'from':accounts[3]})
    # assert roach_nft.totalSupply() == 2, 'totalSupply'
    #
    # with reverts(""):
    #     r = roach_nft.ownerOf(10013)
    #
    # with reverts(""):
    #     r = roach_nft.ownerOf(10014)
    #
    # with reverts(""):
    #     r = roach_nft.ownerOf(10015)
    #
    # # burn second time
    # with reverts(""):
    #     roach_nft.burn(10013, {'from':accounts[3]})
    #
    # # burn unexisting token
    # with reverts(""):
    #     roach_nft.burn(10012, {'from':accounts[3]})
    #
    # # burn unexisting token
    # with reverts(""):
    #     roach_nft.burn(10014, {'from':accounts[3]})
