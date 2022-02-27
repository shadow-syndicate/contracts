import pytest
import logging
import time
from brownie import Wei, reverts

LOGGER = logging.getLogger(__name__)

def test_presale_happy_path(accounts, GenesisSale, weth, roach_nft):
    buyer = accounts[1]
    genesis_sale = accounts[0].deploy(GenesisSale, weth, roach_nft, round(time.time()) - 1, 60*60*24, 100)
    roach_nft.addOperator(genesis_sale)

    status = genesis_sale.getSaleStatus(buyer)
    assert status[0] == True, "presale is active"
    assert status[1] == False, "stage2 is not active"
    assert status[2] == 10_000, "left to mint"
    assert status[5] == 0, "allowedToMintForAccount"

    assert roach_nft.balanceOf(buyer) == 0

    with reverts("Account limit reached"):
        genesis_sale.mint(1, "", {'from':buyer})

    genesis_sale.setWhitelistAddress(buyer, 5, 10, {'from':accounts[0]})

    status = genesis_sale.getSaleStatus(buyer)
    assert status[5] == 5, "allowedToMintForAccount"

    with reverts("Insufficient money"):
        genesis_sale.mint(1, "", {'from':buyer})

    weth.transfer(buyer, 1e18)

    with reverts("ERC20: transfer amount exceeds allowance"):
        genesis_sale.mint(1, "", {'from':buyer})

    weth.approve(genesis_sale, 1e18, {'from':buyer})
    genesis_sale.mint(1, "", {'from':buyer})
    assert roach_nft.balanceOf(buyer) == 1
    status = genesis_sale.getSaleStatus(buyer)
    assert status[5] == 4, "allowedToMintForAccount"

    genesis_sale.mint(4, "", {'from':buyer})
    assert roach_nft.balanceOf(buyer) == 5

    with reverts("Account limit reached"):
        genesis_sale.mint(1, "", {'from':buyer})


def test_sale_stage2_happy_path(accounts, GenesisSale, weth, roach_nft):
    buyer = accounts[1]
    genesis_sale = accounts[0].deploy(GenesisSale, weth, roach_nft, round(time.time()) - 10, 5, 100)
    roach_nft.addOperator(genesis_sale)
    assert roach_nft.balanceOf(buyer) == 0

    with reverts("Insufficient money"):
        genesis_sale.mint(1, "", {'from':buyer})

    weth.transfer(buyer, 10e18)

    with reverts("ERC20: transfer amount exceeds allowance"):
        genesis_sale.mint(100, "", {'from':buyer})

    weth.approve(genesis_sale, 10e18, {'from':buyer})

    genesis_sale.mint(1, "", {'from':buyer})
    assert roach_nft.balanceOf(buyer) == 1

    # with reverts("Limit per tx"):
    #     genesis_sale.mint(101, "", {'from':buyer})

def test_sale_not_started(accounts, GenesisSale, weth, roach_nft):
    buyer = accounts[1]
    genesis_sale = accounts[0].deploy(GenesisSale, weth, roach_nft, round(time.time()) + 10, 5, 100)
    roach_nft.addOperator(genesis_sale)
    assert roach_nft.balanceOf(buyer) == 0

    with reverts("Genesis sale not started yet"):
        genesis_sale.mint(1, "", {'from':buyer})

    status = genesis_sale.getSaleStatus(buyer)
    logging.info("status {}", status)
