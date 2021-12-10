## Roach Racing Club Contracts

### Tests
We use Brownie framework for developing and unit test. For run tests
first please [install it](https://eth-brownie.readthedocs.io/en/stable/install.html)

```bash
brownie pm install OpenZeppelin/openzeppelin-contracts@4.4.0
npm -g i ganache-cli
brownie test
```

## Deployment workflow
Brownie script example:  
```
export WEB3_INFURA_PROJECT_ID=<infura_project_id>
export ETHERSCAN_TOKEN=<etherscan_api_token>
brownie console --network=rinkeby
```
