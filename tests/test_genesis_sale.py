import logging
import time
from brownie import Wei, reverts

LOGGER = logging.getLogger(__name__)

def test_presale_happy_path(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    stage1time = round(time.time()) - 1
    stage1duration = 60 * 60 * 24
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, stage1time, stage1duration, 100, 10_000)
    roach_nft.addOperator(genesis_sale)

    ALLOWED = 5
    BONUS = 10

    status = genesis_sale.getSaleStatus(buyer, 0)
    assert status[0] == 1, "presale is active"
    assert status[1] == 10_000, "left to mint"
    assert status[2] == stage1time + stage1duration, "stage1 finish time"
    assert status[4] == 0, "allowedToMintForAccount"

    assert roach_nft.balanceOf(buyer) == 0


    assert genesis_sale.getAllowedToBuyForAccountOnPresale(buyer, ALLOWED) == ALLOWED, "getAllowedToBuyForAccountOnPresale"

    with reverts("Account limit reached"):
        genesis_sale.mintStage1noSig(1, 0, BONUS, "", {'from':buyer, 'amount': 100})

    # genesis_sale.setWhitelistAddress(buyer, 5, 10, {'from':accounts[0]})

    status = genesis_sale.getSaleStatus(buyer, ALLOWED)
    assert status[4] == ALLOWED, "allowedToMintForAccount"

    with reverts("Insufficient money"):
        genesis_sale.mintStage1noSig(1, ALLOWED, BONUS, "", {'from':buyer, 'amount': 99})

    genesis_sale.mintStage1noSig(1, ALLOWED, BONUS, "", {'from':buyer, 'amount': 100})
    assert roach_nft.balanceOf(buyer) == 1
    status = genesis_sale.getSaleStatus(buyer, ALLOWED)
    assert status[4] == ALLOWED - 1, "allowedToMintForAccount"

    assert genesis_sale.getAllowedToBuyForAccountOnPresale(buyer, ALLOWED) == ALLOWED - 1, "getAllowedToBuyForAccountOnPresale"

    tx = genesis_sale.mintStage1noSig(4, ALLOWED, BONUS, "abc", {'from':buyer, 'amount': 400})

    e = tx.events[0]
    assert e.name == 'Purchase', 'missing event Purchase'
    assert e['count'] == 4, e
    assert e['traitBonus'] == 10
    assert e['syndicate'] == 'abc'
    assert e['account'] == '0x33A4622B82D4c04a53e170c638B944ce27cffce3'

    assert genesis_sale.getAllowedToBuyForAccountOnPresale(buyer, ALLOWED) == 0, "getAllowedToBuyForAccountOnPresale"

    assert roach_nft.balanceOf(buyer) == 5, "balance after mint is 5"

    with reverts("Account limit reached"):
        genesis_sale.mintStage1noSig(1, ALLOWED, BONUS, "", {'from':buyer, 'amount': 100})

    with reverts("Public sale not active"):
        genesis_sale.mintStage2(1, "", {'from':buyer, 'amount': 100})


def test_sale_stage2_happy_path(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    stage1start = round(time.time()) - 10
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, stage1start, 5, 100, 10_000)
    roach_nft.addOperator(genesis_sale)
    assert roach_nft.balanceOf(buyer) == 0

    with reverts("Insufficient money"):
        genesis_sale.mintStage2(1, "", {'from':buyer, 'amount': 99})

    genesis_sale.mintStage2(1, "", {'from':buyer, 'amount': 100})
    assert roach_nft.balanceOf(buyer) == 1

    status = genesis_sale.getSaleStatus(buyer, 0)
    assert status[0] == 2, "stage2 started"
    assert status[2] == 0, "stage2 no finish time"

    with reverts("Limit per tx"):
        genesis_sale.mintStage2(101, "", {'from':buyer, 'amount': 10100})

    with reverts("Presale not active"):
        genesis_sale.mintStage1noSig(1, 10, 10, "", {'from':buyer, 'amount': 100})


def test_sale_not_started(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    stage1time = round(time.time()) + 10
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, stage1time, 5, 100, 10_000)
    roach_nft.addOperator(genesis_sale)
    assert roach_nft.balanceOf(buyer) == 0

    ALLOWED = 5
    BONUS = 10

    with reverts("Presale not active"):
        genesis_sale.mintStage1noSig(1, ALLOWED, BONUS, "", {'from':buyer, 'amount': 100})

    with reverts("Public sale not active"):
        genesis_sale.mintStage2(1, "", {'from':buyer, 'amount': 100})

    status = genesis_sale.getSaleStatus(buyer, 0)
    assert status[0] == 0, "presale not started"
    assert status[2] == stage1time, "stage1 start time"


def test_sale_ended(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, round(time.time()) - 10, 5, 100, 3)
    roach_nft.addOperator(genesis_sale)
    assert roach_nft.balanceOf(buyer) == 0

    status = genesis_sale.getSaleStatus(buyer, 0)
    assert status[0] == 2, "stage2 active"
    assert status[2] == 0, "no finish time"

    genesis_sale.mintStage2(3, "", {'from':buyer, 'amount': 300})

    status = genesis_sale.getSaleStatus(buyer, 0)
    assert status[0] == 3, "stage2 ended"

    with reverts("Presale not active"):
        genesis_sale.mintStage1noSig(1, 1, 1, "", {'from':buyer, 'amount': 100})

    with reverts("Public sale not active"):
        genesis_sale.mintStage2(1, "", {'from':buyer, 'amount': 100})

def test_buy_left_tokens(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, round(time.time()) - 10, 5, 100, 3)
    roach_nft.addOperator(genesis_sale)
    assert roach_nft.balanceOf(buyer) == 0

    balanceBefore = buyer.balance()

    status = genesis_sale.getSaleStatus(buyer, 0)
    assert status[0] == 2, "stage2 active"

    genesis_sale.mintStage2(5, "", {'from':buyer, 'amount': 500, 'gas_price': 0})

    status = genesis_sale.getSaleStatus(buyer, 0)
    assert status[0] == 3, "stage2 ended"

    with reverts("Public sale not active"):
        genesis_sale.mintStage2(1, "", {'from':buyer, 'amount': 100})
    assert roach_nft.balanceOf(buyer) == 3, 'Buy only 3 of 5 requested'

    balanceAfter = buyer.balance()
    assert balanceBefore - balanceAfter == 3*100, 'Take money only for 3 roaches'


def test_not_enough_money(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, round(time.time()) - 10, 50, 100, 3)
    roach_nft.addOperator(genesis_sale)
    # genesis_sale.setWhitelistAddress(buyer, 5, 10, {'from':accounts[0]})

    assert roach_nft.balanceOf(buyer) == 0

    balanceBefore = buyer.balance()

    with reverts("Insufficient money"):
        genesis_sale.mintStage1noSig(5, 5, 25, "", {'from':buyer, 'amount': 200, 'gas_price': 0})

    assert roach_nft.balanceOf(buyer) == 0, 'Buy 0 of 5 requested because of low money'

    balanceAfter = buyer.balance()
    assert balanceBefore == balanceAfter, 'Do not take money'

    status = genesis_sale.getSaleStatus(buyer, 5)
    assert status[4] == 5, "left to mint for acount"


def test_buy_all_tokens_on_presale(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, round(time.time()) - 10, 50, 100, 3)
    roach_nft.addOperator(genesis_sale)
    # genesis_sale.setWhitelistAddress(buyer, 5, 10, {'from':accounts[0]})

    assert roach_nft.balanceOf(buyer) == 0

    genesis_sale.mintStage1noSig(3, 10, 25, "", {'from':buyer, 'amount': 300})

    status = genesis_sale.getSaleStatus(buyer, 10)
    assert status[0] == 3, "Sale is over"
    assert status[1] == 0, "left to mint"


