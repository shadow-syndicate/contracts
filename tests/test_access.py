import logging
import time
from brownie import Wei, reverts

LOGGER = logging.getLogger(__name__)

def test_access_genome_provider(GenomeProviderPolygon):
    # TODO
    return

def test_access(accounts, GenesisSale, weth, roach_nft):
    stage1time = round(time.time()) - 1
    stage1duration = 60 * 60 * 24
    genesis_sale = accounts[0].deploy(GenesisSale, weth, roach_nft, stage1time, stage1duration, 100, 10_000)

    with reverts("Access denied"):
        roach_nft.mint(accounts[0], "0x0", [0,0], 0, 0, {'from':accounts[1]})

    with reverts("Access denied"):
        roach_nft.mintGen0(accounts[0], 0, "syndicate", {'from':accounts[1]})

    with reverts("Access denied"):
        roach_nft.setGenome(1, "0x0", {'from':accounts[1]})

    with reverts("Ownable: caller is not the owner"):
        roach_nft.setRevealCooldown(1, {'from':accounts[1]})

    with reverts("Ownable: caller is not the owner"):
        roach_nft.setMetadataContract(weth, {'from':accounts[1]})

    with reverts("Access denied"):
        genesis_sale.setWhitelistAddress(accounts[1], 5, 25, {'from':accounts[1]})

    with reverts("Access denied"):
        genesis_sale.setWhitelistAddressBatch([accounts[1]], 5, 25, {'from':accounts[1]})

    with reverts("Access denied"):
        genesis_sale.mintOperator(accounts[1], 5, 25, "syndicate", {'from':accounts[1]})
