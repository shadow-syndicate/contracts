import logging
import time

LOGGER = logging.getLogger(__name__)

def test_nft(accounts, chain, roach_nft):
    roach_nft.mint(accounts[1], "0x123456", [1, 2], 12, 534)
    last = roach_nft.lastRoachId()
    r = roach_nft.getRoach(last)

    assert r[0] == "0x123456", 'genome'
    assert r[1] == [1, 2], 'parents'
    assert abs(r[2] - round(chain.time())) < 5, 'creationTime'
    assert abs(r[3] - round(chain.time())) < 305, 'canRevealTime'
    assert r[4] == 0, 'revealTime'
    assert r[5] == 12, 'generation'
    assert r[6] == 534, 'resistance'
    # assert r[6] == '', 'name'
