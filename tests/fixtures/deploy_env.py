import pytest
import time


@pytest.fixture
def metadata(accounts, Metadata):
    result = accounts[0].deploy(Metadata, "https://metadev.roachracingclub.com/roach/")
    yield result

@pytest.fixture
def roach_nft(accounts, RoachNFT, GenomeProvider, metadata):
    result = accounts[0].deploy(RoachNFT, metadata)
    provider = accounts[0].deploy(GenomeProvider, result)
    provider.setTraitConfig(1, [1], [0,1,2,3], [1,3,4,1], [5,2,1,1])
    provider.setTraitConfig(2, [2], [0,1], [1, 1], [1,1])
    provider.setTraitConfig(3, [3], [0,1,2], [2, 1, 0], [0, 1, 2])
    provider.setTraitConfig(4, [4], [0], [1], [1])
    provider.setTraitConfig(5, [5], [0], [1], [1])
    provider.setTraitConfig(6, [6], [0], [1], [1])
    result.setGenomeProviderContract(provider)
    yield result

@pytest.fixture
def weth(accounts, TokenMock):
    return accounts[0].deploy(TokenMock, "Dummy WETH", "WETH")

@pytest.fixture
def genesis_sale(accounts, GenesisSale, weth, roach_nft):
    return accounts[0].deploy(GenesisSale, weth, roach_nft, round(time.time()), 60*60*24)

