import pytest
import time


@pytest.fixture
def metadata(accounts, Metadata):
    result = accounts[0].deploy(Metadata,
                                "https://meta.roachracingclub.com/roach/",
                                "https://meta.roachracingclub.com/contract/")
    yield result

@pytest.fixture
def roach_nft(accounts, RoachNFT, metadata):
    result = accounts[0].deploy(RoachNFT, metadata)
    yield result

@pytest.fixture
def trax(accounts, TRAX):
    result = accounts[0].deploy(TRAX)
    yield result

@pytest.fixture
def genesis_sale(accounts, GenesisMint, roach_nft):
    return accounts[0].deploy(GenesisMint, roach_nft, round(time.time()), 60*60*24)

@pytest.fixture
def reveal(accounts, RevealTest, roach_nft):
    deployed = accounts[0].deploy(RevealTest, roach_nft)
    roach_nft.addOperator(deployed)
    return deployed

