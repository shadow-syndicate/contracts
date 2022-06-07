import logging
import time
from brownie import Wei, reverts

LOGGER = logging.getLogger(__name__)

def test_sale_happy_path(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    stage1time = round(time.time()) - 1
    stage1duration = 60 * 60 * 24
    PRICE = 100
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, stage1time, stage1duration, 10_000)
    roach_nft.addOperator(genesis_sale)

    ALLOWED = 5
    BONUS = 10

    status = genesis_sale.getSaleStatus(buyer, 0)
    assert status[0] == 1, "sale is active"
    assert status[1] == 10_000, "left to mint"
    assert status[2] == stage1time + stage1duration, "stage1 finish time"
    assert status[4] == 0, "allowedToMintForAccount"

    assert roach_nft.balanceOf(buyer) == 0


    assert genesis_sale.getAllowedToBuyForAccount(buyer, ALLOWED) == ALLOWED, "getAllowedToBuyForAccount"

    with reverts("Account limit reached"):
        genesis_sale.mintStage1noSig(1, 0, PRICE, BONUS, "", {'from':buyer, 'amount': 100})

    # genesis_sale.setWhitelistAddress(buyer, 5, 10, {'from':accounts[0]})

    status = genesis_sale.getSaleStatus(buyer, ALLOWED)
    assert status[4] == ALLOWED, "allowedToMintForAccount"

    with reverts("Insufficient money"):
        genesis_sale.mintStage1noSig(1, ALLOWED, PRICE, BONUS, "", {'from':buyer, 'amount': 99})

    genesis_sale.mintStage1noSig(1, ALLOWED, PRICE, BONUS, "", {'from':buyer, 'amount': 100})
    assert roach_nft.balanceOf(buyer) == 1
    status = genesis_sale.getSaleStatus(buyer, ALLOWED)
    assert status[4] == ALLOWED - 1, "allowedToMintForAccount"

    assert genesis_sale.getAllowedToBuyForAccount(buyer, ALLOWED) == ALLOWED - 1, "getAllowedToBuyForAccount"

    tx = genesis_sale.mintStage1noSig(4, ALLOWED, PRICE, BONUS, "abc", {'from':buyer, 'amount': 400})

    e = tx.events[0]
    assert e.name == 'Purchase', 'missing event Purchase'
    assert e['count'] == 4, e
    assert e['traitBonus'] == 10
    assert e['syndicate'] == 'abc'
    assert e['account'] == '0x33A4622B82D4c04a53e170c638B944ce27cffce3'

    assert genesis_sale.getAllowedToBuyForAccount(buyer, ALLOWED) == 0, "getAllowedToBuyForAccount"

    assert roach_nft.balanceOf(buyer) == 5, "balance after mint is 5"

    with reverts("Account limit reached"):
        genesis_sale.mintStage1noSig(1, ALLOWED, PRICE, BONUS, "", {'from':buyer, 'amount': 100})


def test_withdraw(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    stage1start = round(time.time()) - 10
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, stage1start, 50, 10_000)
    roach_nft.addOperator(genesis_sale)

    before = buyer.balance()
    genesis_sale.mintStage1noSig(13, 13, 0, 0, "", {'from':buyer, 'amount': 1500, 'gasPrice': 0})
    assert roach_nft.balanceOf(buyer) == 13
    after = buyer.balance()
    assert after - before == -1500, "No refund - take all donation"

    before = accounts[0].balance()
    genesis_sale.withdrawEther({'from': accounts[0], 'gasPrice': 0})
    after = accounts[0].balance()
    assert after - before == 1500, "Withdraw all ether"


def test_sale_not_started(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    stage1time = round(time.time()) + 10
    PRICE = 100
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, stage1time, 5, 10_000)
    roach_nft.addOperator(genesis_sale)
    assert roach_nft.balanceOf(buyer) == 0

    ALLOWED = 5
    BONUS = 10

    with reverts("Sale not active"):
        genesis_sale.mintStage1noSig(1, ALLOWED, PRICE, BONUS, "", {'from':buyer, 'amount': 100})

    status = genesis_sale.getSaleStatus(buyer, 0)
    assert status[0] == 0, "sale not started"
    assert status[2] == stage1time, "stage1 start time"


def test_sale_ended_soldout(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, round(time.time()) - 10, 50, 3)
    roach_nft.addOperator(genesis_sale)
    assert roach_nft.balanceOf(buyer) == 0

    status = genesis_sale.getSaleStatus(buyer, 0)
    assert status[0] == 1, "stage1 active"
    assert status[2] != 0, "finish time set"

    genesis_sale.mintStage1noSig(3, 10, 0, 0, "", {'from':buyer, 'amount': 300})

    status = genesis_sale.getSaleStatus(buyer, 0)
    assert status[0] == 2, "stage2 ended"

    with reverts("Sale not active"):
        genesis_sale.mintStage1noSig(1, 1, 1, 1, "", {'from':buyer, 'amount': 100})


def test_buy_left_tokens(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, round(time.time()) - 10, 50, 3)
    roach_nft.addOperator(genesis_sale)
    assert roach_nft.balanceOf(buyer) == 0

    balanceBefore = buyer.balance()

    status = genesis_sale.getSaleStatus(buyer, 0)
    assert status[0] == 1, "stage2 active"

    genesis_sale.mintStage1noSig(5, 5, 0, 0, "", {'from':buyer, 'amount': 500, 'gas_price': 0})

    status = genesis_sale.getSaleStatus(buyer, 0)
    assert status[0] == 2, "stage2 ended"

    with reverts("Sale not active"):
        genesis_sale.mintStage1noSig(1, 1, 0, 0, "", {'from':buyer, 'amount': 100})
    assert roach_nft.balanceOf(buyer) == 3, 'Buy only 3 of 5 requested'

    balanceAfter = buyer.balance()
    assert balanceBefore - balanceAfter == 500, 'Take all money'


def test_not_enough_money(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    PRICE = 100
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, round(time.time()) - 10, 50, 3)
    roach_nft.addOperator(genesis_sale)
    # genesis_sale.setWhitelistAddress(buyer, 5, 10, {'from':accounts[0]})

    assert roach_nft.balanceOf(buyer) == 0

    balanceBefore = buyer.balance()

    with reverts("Insufficient money"):
        genesis_sale.mintStage1noSig(5, 5, PRICE, 25, "", {'from':buyer, 'amount': 200, 'gas_price': 0})

    assert roach_nft.balanceOf(buyer) == 0, 'Buy 0 of 5 requested because of low money'

    balanceAfter = buyer.balance()
    assert balanceBefore == balanceAfter, 'Do not take money'

    status = genesis_sale.getSaleStatus(buyer, 5)
    assert status[4] == 5, "left to mint for acount"


def test_buy_all_tokens_on_sale(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    PRICE = 100
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, round(time.time()) - 10, 50, 3)
    roach_nft.addOperator(genesis_sale)
    # genesis_sale.setWhitelistAddress(buyer, 5, 10, {'from':accounts[0]})

    assert roach_nft.balanceOf(buyer) == 0

    genesis_sale.mintStage1noSig(3, 10, PRICE, 25, "", {'from':buyer, 'amount': 300})

    status = genesis_sale.getSaleStatus(buyer, 10)
    assert status[0] == 2, "Sale is over"
    assert status[1] == 0, "left to mint"


def test_total_supply(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    PRICE = 100
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, round(time.time()) - 10, 50, 100)
    roach_nft.addOperator(genesis_sale)

    assert genesis_sale.totalMinted() == 0, "Default supply 100"
    genesis_sale.mintOperator(buyer, 1, 0, "")
    assert genesis_sale.totalMinted() == 1, "Supply"

    genesis_sale.mintStage1noSig(3, 10, PRICE, 25, "", {'from':buyer, 'amount': 300})
    assert genesis_sale.totalMinted() == 4, "Supply"

    status = genesis_sale.getSaleStatus(buyer, 10)
    assert status[1] == 96, "left to mint"

def test_set_signer(accounts, GenesisSaleDebug, roach_nft):
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, round(time.time()) - 10, 50, 100)

    assert genesis_sale.signerAddress() == accounts[0], "default signer"

    genesis_sale.setSigner(accounts[2])
    assert genesis_sale.signerAddress() == accounts[2], "new signer"

def test_operator_mint_count_limit(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, round(time.time()) - 10, 50, 3)
    roach_nft.addOperator(genesis_sale)
    assert roach_nft.balanceOf(buyer) == 0

    genesis_sale.mintStage1noSig(1, 1, 100, 0, "", {'from':buyer, 'amount': 100, 'gas_price': 0})

    assert genesis_sale.totalMinted() == 1, "totalMinted"

    genesis_sale.mintOperator(buyer, 2, 0, "", {'from':accounts[0]})
    assert genesis_sale.totalMinted() == 3, "totalMinted"
    assert roach_nft.balanceOf(buyer) == 3

    with reverts("Sale is over"):
        genesis_sale.mintOperator(buyer, 1, 0, "", {'from':accounts[0]})

def test_sig(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, round(time.time()) - 10, 50, 3)
    roach_nft.addOperator(genesis_sale)

    sig = {"sig":
               {"v":"0x1c",
                "r":"0x660bd899057508ef397414b0dbb59c6ca5fbeee4e625d5124bae1122f76b8027",
                "s":"0x16e8d6ff1f8327b4597ea57c72775ed7a6fd007abd919b44880fa8bd3f6d866d"},
           "account":"0x5c8eA699a610B09c5b6bf3dbbE1b2120F9Fd00B6",
           "limit":"50",
           "price":"100000000000000000",
           "bonus":"25",
           "signer":"0x5c8eA699a610B09c5b6bf3dbbE1b2120F9Fd00B6"
    }

    with reverts("Wrong signature"):
        genesis_sale.mint(1, sig["limit"], sig["price"], sig["bonus"], "",
                            sig["sig"]["v"], sig["sig"]["r"], sig["sig"]["s"],
                            {'from':buyer, 'amount': 100})
    isValid = genesis_sale.isValidSignature(sig["account"], sig["limit"], sig["price"], sig["bonus"],
                                            sig["sig"]["v"], sig["sig"]["r"], sig["sig"]["s"])
    assert isValid == False, "sig wrong"

    genesis_sale.setSigner(sig["signer"])
    isValid = genesis_sale.isValidSignature(sig["account"], sig["limit"], sig["price"], sig["bonus"],
                            sig["sig"]["v"], sig["sig"]["r"], sig["sig"]["s"])
    assert isValid, "sig ok"

def test_whitelist_price(accounts, GenesisSaleDebug, roach_nft):
    buyer = accounts[1]
    PRICE = 100
    BONUS = 25
    genesis_sale = accounts[0].deploy(GenesisSaleDebug, roach_nft, round(time.time()) - 10, 50, 3)
    roach_nft.addOperator(genesis_sale)

    with reverts("Insufficient money"):
        genesis_sale.mintStage1noSig(1, 10, PRICE * 2, BONUS, "", {'from':buyer, 'amount': PRICE})

    WL_PRICE = 10
    before = buyer.balance()
    genesis_sale.mintStage1noSig(1, 10, WL_PRICE, BONUS, "", {'from':buyer, 'amount': PRICE, 'gasPrice': 0})
    after = buyer.balance()
    assert before - after == PRICE, "take all money"

    WL_PRICE = 0
    before = buyer.balance()
    genesis_sale.mintStage1noSig(1, 10, WL_PRICE, BONUS, "", {'from':buyer, 'gasPrice': 0})
    after = buyer.balance()
    assert before == after, "zero price whitelist"
