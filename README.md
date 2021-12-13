## Roach Racing Club Contracts

## Tests
We use Brownie framework for developing and unit test. For run tests
first please [install it](https://eth-brownie.readthedocs.io/en/stable/install.html)

```bash
brownie pm install OpenZeppelin/openzeppelin-contracts@4.4.0
brownie pm install smartcontractkit/chainlink@0.10.15
npm -g i ganache-cli
brownie test
```

## Deployment workflow
Brownie script example:  
```
export WEB3_INFURA_PROJECT_ID=<infura_project_id>
export ETHERSCAN_TOKEN=<etherscan_api_token>
brownie run ./deploy.py --network=rinkeby
```

## Contract structure

# RoachNFT

Base NFT storage. Stores token ownership, genomes, parents.
Token is created in Egg stage.
To finalize creating and give birth to Roach token you should 
call giveBirth. There is birth cooldown period (by default 1 week).
This contract is non-upgradable.

# Sale

Operates limited token sale. There can be only 10k Gen0 Roach tokens sold.

# GenomeProvider

Generates genome for each new Roach token using ChainLink VRF.
ChainLink generates random numbers in asynchronous mode, so genome for Roach token
will be filled after some time when token was minted.
You can't give birth to Roach token while genome is empty.

# Metadata

Upgradable contract that provides Metadata for Roach tokens. 
Full metadata will be available only after Roach is born.

