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
    provider.setTraitWeight(1, [1,3,4,1], [5,2,1,1])
    provider.setTraitWeight(2, [1, 1], [1,1])
    provider.setTraitWeight(3, [2, 1, 0], [0, 1, 2])
    provider.setTraitWeight(4, [1], [1])
    provider.setTraitWeight(5, [1], [1])
    provider.setTraitWeight(6, [1], [1])
    result.setGenomeProviderContract(provider)
    yield result

@pytest.fixture
def weth(accounts, TokenMock):
    return accounts[0].deploy(TokenMock, "Dummy WETH", "WETH")

@pytest.fixture
def genesis_sale(accounts, GenesisSale, weth, roach_nft):
    return accounts[0].deploy(GenesisSale, weth, roach_nft, round(time.time()), 60*60*24)

