import pytest
import time


@pytest.fixture
def metadata(accounts, Metadata):
    result = accounts[0].deploy(Metadata, "https://metadev.roachracingclub.com/roach/")
    yield result

@pytest.fixture
def roach_nft(accounts, RoachNFT, GenomeProvider, metadata):
    result = accounts[0].deploy(RoachNFT, metadata)
    genome_provider = accounts[0].deploy(GenomeProvider, result)
    result.setGenomeProviderContract(genome_provider)
    yield result

@pytest.fixture
def weth(accounts, TokenMock):
    return accounts[0].deploy(TokenMock, "Dummy WETH", "WETH")

@pytest.fixture
def genesis_sale(accounts, GenesisSale, weth, roach_nft):
    return accounts[0].deploy(GenesisSale, weth, roach_nft, round(time.time()), 60*60*24)

