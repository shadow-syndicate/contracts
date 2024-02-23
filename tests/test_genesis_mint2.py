import logging
import time
from brownie import Wei, reverts

LOGGER = logging.getLogger(__name__)

def test_mint_happy_path(accounts, GenesisMint2Debug, roach_nft, trax):
    buyer = accounts[1]
    stage1time = round(time.time()) - 1
    stage1duration = 60 * 60 * 24
    PRICE = Wei("1 ether")
    genesis_mint = accounts[0].deploy(GenesisMint2Debug, roach_nft, trax, stage1time)
    roach_nft.addOperator(genesis_mint)
    trax.setWhitelistedTo(genesis_mint, {'from':accounts[0]})

    ALLOWED = 1

    status = genesis_mint.getMintStatus(buyer, 0)
    assert status[0] == 1, "sale is active"
    assert status[1] == 10_000, "left to mint"
    assert status[2] == 0, "unlimited"
    assert status[3] == 0, "allowedToMintForAccount"
    assert status[4] == PRICE, "price"

    ########## Whitelist ############

    assert roach_nft.balanceOf(buyer) == 0

    assert genesis_mint.getAllowedToMintForAccount(buyer, ALLOWED) == ALLOWED, "getAllowedToMintForAccount"

    with reverts("Account limit reached"):
        genesis_mint.mintWhitelistedNoSig(0, {'from':buyer})

    genesis_mint.mintWhitelistedNoSig(ALLOWED, {'from':buyer})
    assert roach_nft.balanceOf(buyer) == 1

    status = genesis_mint.getMintStatus(buyer, ALLOWED)
    assert status[3] == 0, "allowedToMintForAccount"

    with reverts("Account limit reached"):
        genesis_mint.mintWhitelistedNoSig(ALLOWED, {'from':buyer})

    ########## TRAX ############

    genesis_mint.setProbability(100*100, {'from':accounts[0]})

    with reverts("ERC20: transfer amount exceeds balance"):
        genesis_mint.mintForTrax({'from':buyer})

    trax.mint(buyer, PRICE, {'from':accounts[0]})
    assert trax.balanceOf(buyer) == PRICE
    genesis_mint.mintForTrax({'from':buyer})
    assert roach_nft.balanceOf(buyer) == 2
    assert trax.balanceOf(genesis_mint) == PRICE
    assert trax.balanceOf(buyer) == 0

    # trax.mint(buyer, Wei("1 ether"), {'from':accounts[0]})
    with reverts("ERC20: transfer amount exceeds balance"):
        genesis_mint.mintForTrax({'from':buyer})
    assert roach_nft.balanceOf(buyer) == 2
    assert trax.balanceOf(genesis_mint) == PRICE
    assert trax.balanceOf(buyer) == 0

    genesis_mint.setProbability(0, {'from':accounts[0]})

    with reverts("ERC20: transfer amount exceeds balance"):
        genesis_mint.mintForTrax({'from':buyer})
    assert roach_nft.balanceOf(buyer) == 2
    assert trax.balanceOf(genesis_mint) == PRICE
    assert trax.balanceOf(buyer) == 0

    trax.mint(buyer, Wei("1 ether"), {'from':accounts[0]})
    genesis_mint.mintForTrax({'from':buyer})
    assert roach_nft.balanceOf(buyer) == 2
    assert trax.balanceOf(genesis_mint) == PRICE*2
    assert trax.balanceOf(buyer) == 0
