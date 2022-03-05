## Roach Racing Club Contracts

## Contracts structure

# RoachNFT

Base NFT storage. Stores token ownership, genomes, parents.
Token is created in Egg stage.
To finalize creating and give birth to Roach token you should 
call giveBirth. There is birth cooldown period (by default 1 week).
This contract is non-upgradable.

# GensisSale

Operates limited token sale. There can be only 10k Gen0 Roach tokens sold.

Functions:
```
function getSaleStatus(address account) external view returns (
    uint stage,
    uint leftToMint,
    uint nextStageTimestamp,
    uint price,
    uint allowedToMintForAccount,
    uint accountBonus)
```

```
function mint(uint count, string calldata syndicate)
```

# GenomeProvider

Generates genome for each new Roach token using ChainLink VRF.
ChainLink generates random numbers in asynchronous mode, so genome for Roach token
will be filled after some time when token was minted.
You can't give birth to Roach token while genome is empty.

# Metadata

Upgradable contract that provides Metadata for Roach tokens. 
Full metadata will be available only after Roach is born.

## Deployment workflow

### Environment setup 
We use [Brownie](https://eth-brownie.readthedocs.io/en/stable/install.html) framework for testing and develoyment.

```bash
pip install eth-brownie
brownie pm install OpenZeppelin/openzeppelin-contracts@4.4.0
brownie pm install smartcontractkit/chainlink@0.10.15
npm -g i ganache-cli
```

### Testing

```
brownie test
```

## Testnet deployment
Setup environment variables:
```
export WEB3_INFURA_PROJECT_ID=<infura_project_id>
export ETHERSCAN_TOKEN=<etherscan_api_token>
export POLYGONSCAN_TOKEN=<polygoncan_api_token>
```
For Polygon testnet (Mumbai): 
```
brownie networks add Polygon mumbai host=https://polygon-mumbai.g.alchemy.com/v2/$KEY chainid=80001 explorer=https://mumbai.polygonscan.com/
brownie run ./deploy.py --network=mumbai
```
For Rinkeby testnet:
```
brownie run ./deploy.py --network=rinkeby
```
You need to request [testnet LINK](https://faucets.chain.link/rinkeby) to GenomeProvider contract.
To mint tokens on GenesisSale you need to request [testnet WETH](https://faucets.chain.link/rinkeby) to your address.
