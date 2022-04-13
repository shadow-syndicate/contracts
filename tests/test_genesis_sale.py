import logging
import time
from brownie import Wei, reverts

LOGGER = logging.getLogger(__name__)

def test_presale_happy_path(accounts, GenesisSale, weth, roach_nft):
    buyer = accounts[1]
    stage1time = round(time.time()) - 1
    stage1duration = 60 * 60 * 24
    genesis_sale = accounts[0].deploy(GenesisSale, weth, roach_nft, stage1time, stage1duration, 100, 10_000)
    roach_nft.addOperator(genesis_sale)

    status = genesis_sale.getSaleStatus(buyer)
    assert status[0] == 1, "presale is active"
    assert status[1] == 10_000, "left to mint"
    assert status[2] == stage1time + stage1duration, "stage1 finish time"
    assert status[4] == 0, "allowedToMintForAccount"

    assert roach_nft.balanceOf(buyer) == 0

    with reverts("Account limit reached"):
        genesis_sale.mint(1, "", {'from':buyer})

    genesis_sale.setWhitelistAddress(buyer, 5, 10, {'from':accounts[0]})

    status = genesis_sale.getSaleStatus(buyer)
    assert status[4] == 5, "allowedToMintForAccount"

    with reverts("Insufficient money"):
        genesis_sale.mint(1, "", {'from':buyer})

    weth.transfer(buyer, 1e18)

    with reverts("ERC20: transfer amount exceeds allowance"):
        genesis_sale.mint(1, "", {'from':buyer})

    weth.approve(genesis_sale, 1e18, {'from':buyer})
    genesis_sale.mint(1, "", {'from':buyer})
    assert roach_nft.balanceOf(buyer) == 1
    status = genesis_sale.getSaleStatus(buyer)
    assert status[4] == 4, "allowedToMintForAccount"

    tx = genesis_sale.mint(4, "abc", {'from':buyer})

    e = tx.events[2]
    assert e.name == 'Purchase', 'missing event Purchase'
    assert e['count'] == 4, e
    assert e['traitBonus'] == 10
    assert e['syndicate'] == 'abc'
    assert e['account'] == '0x33A4622B82D4c04a53e170c638B944ce27cffce3'

    assert roach_nft.balanceOf(buyer) == 5, "balance after mint is 5"

    with reverts("Account limit reached"):
        genesis_sale.mint(1, "", {'from':buyer})


def test_sale_stage2_happy_path(accounts, GenesisSale, weth, roach_nft):
    buyer = accounts[1]
    stage1start = round(time.time()) - 10
    genesis_sale = accounts[0].deploy(GenesisSale, weth, roach_nft, stage1start, 5, 100, 10_000)
    roach_nft.addOperator(genesis_sale)
    assert roach_nft.balanceOf(buyer) == 0

    with reverts("Insufficient money"):
        genesis_sale.mint(1, "", {'from':buyer})

    weth.transfer(buyer, 10e18)

    with reverts("ERC20: transfer amount exceeds allowance"):
        genesis_sale.mint(1, "", {'from':buyer})

    weth.approve(genesis_sale, 10e18, {'from':buyer})

    genesis_sale.mint(1, "", {'from':buyer})
    assert roach_nft.balanceOf(buyer) == 1

    status = genesis_sale.getSaleStatus(buyer)
    assert status[0] == 2, "stage2 started"
    assert status[2] == 0, "stage2 no finish time"

    with reverts("Limit per tx"):
        genesis_sale.mint(101, "", {'from':buyer})

def test_sale_not_started(accounts, GenesisSale, weth, roach_nft):
    buyer = accounts[1]
    stage1time = round(time.time()) + 10
    genesis_sale = accounts[0].deploy(GenesisSale, weth, roach_nft, stage1time, 5, 100, 10_000)
    roach_nft.addOperator(genesis_sale)
    assert roach_nft.balanceOf(buyer) == 0

    with reverts("Sale not started yet"):
        genesis_sale.mint(1, "", {'from':buyer})

    status = genesis_sale.getSaleStatus(buyer)
    assert status[0] == 0, "presale not started"
    assert status[2] == stage1time, "stage1 start time"

def test_sale_ended(accounts, GenesisSale, weth, roach_nft):
    buyer = accounts[1]
    genesis_sale = accounts[0].deploy(GenesisSale, weth, roach_nft, round(time.time()) - 10, 5, 100, 3)
    roach_nft.addOperator(genesis_sale)
    assert roach_nft.balanceOf(buyer) == 0

    weth.transfer(buyer, 1e18)
    weth.approve(genesis_sale, 1e18, {'from':buyer})

    status = genesis_sale.getSaleStatus(buyer)
    assert status[0] == 2, "stage2 active"
    assert status[2] == 0, "no finish time"

    genesis_sale.mint(3, "", {'from':buyer})

    status = genesis_sale.getSaleStatus(buyer)
    assert status[0] == 3, "stage2 ended"

    with reverts("Sale is over"):
        genesis_sale.mint(1, "", {'from':buyer})

def test_buy_left_tokens(accounts, GenesisSale, weth, roach_nft):
    buyer = accounts[1]
    genesis_sale = accounts[0].deploy(GenesisSale, weth, roach_nft, round(time.time()) - 10, 5, 100, 3)
    roach_nft.addOperator(genesis_sale)
    assert roach_nft.balanceOf(buyer) == 0

    weth.transfer(buyer, 1000)
    weth.approve(genesis_sale, 1e18, {'from':buyer})
    balanceBefore = weth.balanceOf(buyer)

    status = genesis_sale.getSaleStatus(buyer)
    assert status[0] == 2, "stage2 active"

    genesis_sale.mint(5, "", {'from':buyer})

    status = genesis_sale.getSaleStatus(buyer)
    assert status[0] == 3, "stage2 ended"

    with reverts("Sale is over"):
        genesis_sale.mint(1, "", {'from':buyer})
    assert roach_nft.balanceOf(buyer) == 3, 'Buy only 3 of 5 requested'

    balanceAfter = weth.balanceOf(buyer)
    assert balanceBefore - balanceAfter == 3*100, 'Take money only for 3 roaches'

def test_not_enough_money(accounts, GenesisSale, weth, roach_nft):
    buyer = accounts[1]
    genesis_sale = accounts[0].deploy(GenesisSale, weth, roach_nft, round(time.time()) - 10, 50, 100, 3)
    roach_nft.addOperator(genesis_sale)
    genesis_sale.setWhitelistAddress(buyer, 5, 10, {'from':accounts[0]})

    assert roach_nft.balanceOf(buyer) == 0

    weth.transfer(buyer, 250)
    weth.approve(genesis_sale, 1e18, {'from':buyer})
    balanceBefore = weth.balanceOf(buyer)

    genesis_sale.mint(5, "", {'from':buyer})

    assert roach_nft.balanceOf(buyer) == 2, 'Buy only 2 of 5 requested because of low money'

    balanceAfter = weth.balanceOf(buyer)
    assert balanceBefore - balanceAfter == 2*100, 'Take money only for 2 roaches'

    status = genesis_sale.getSaleStatus(buyer)
    assert status[4] == 3, "left to mint for acount"

    with reverts("Insufficient money"):
        genesis_sale.mint(1, "", {'from':buyer})

def test_buy_all_tokens_on_presale(accounts, GenesisSale, weth, roach_nft):
    buyer = accounts[1]
    genesis_sale = accounts[0].deploy(GenesisSale, weth, roach_nft, round(time.time()) - 10, 50, 100, 3)
    roach_nft.addOperator(genesis_sale)
    genesis_sale.setWhitelistAddress(buyer, 5, 10, {'from':accounts[0]})

    assert roach_nft.balanceOf(buyer) == 0

    weth.transfer(buyer, 300)
    weth.approve(genesis_sale, 1e18, {'from':buyer})
    balanceBefore = weth.balanceOf(buyer)

    genesis_sale.mint(3, "", {'from':buyer})

    status = genesis_sale.getSaleStatus(buyer)
    assert status[0] == 3, "Sale is over"
    assert status[1] == 0, "left to mint"

