# veIB Migration


This repository hosts the smart contracts that implement the migration logic for veIB from FTM to OP


## Install

```bash
# Install project dependencies
npm install
```

## Environment Variables
Please setup your own ```.env``` file based on the variables in ```env-template``` file.
## Commands

```bash
# Format code
npm run format

# Unit test coverage
npm run coverage

```

## Deployment
1. In ```hardhat.config.ts```, fill in the ```veIB``` address for OP
2. Execute:
    ```bash
    npx hardhat deploy --tags deploy-dest --network optimism
    ```
3. In ```001_deploy_src_chain.ts```, fill in the ```receiver``` address (veMigrationDest deployed in Step 2)
4. Execute:
    ```bash
    npx hardhat deploy --tags deploy-src --network fantom
    ```
5. In ```002_setup_dest.ts```, fill in the ```sender``` (veMigrationSrc in Step 4), ```prepaidFees```
6. Execute:
    ```bash
    npx hardhat deploy --tags setup-dest --network fantom
    ```
7.  Make sure veMigrationDest has minter access to IB token on OP.

## Verify

```
npx hardhat etherscan-verify --network optimism
npx hardhat etherscan-verify --network fantom
```


## Tests
[Source](https://rinkeby.etherscan.io/tx/0xc6f7dc0936b07a63391c2acc62d40df297be88da5bc60a61d5e3fab86dd61b3e)

[Destination](https://testnet.ftmscan.com/tx/0x363e7d4db8173f0aa0b5c79153df21c0c2854f63690185050355df65f7782774)

