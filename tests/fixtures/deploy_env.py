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
def weth(accounts, TokenMock):
    return accounts[0].deploy(TokenMock, "Dummy WETH", "WETH")

@pytest.fixture
def genesis_sale(accounts, GenesisSale, weth, roach_nft):
    return accounts[0].deploy(GenesisSale, weth, roach_nft, round(time.time()), 60*60*24)

