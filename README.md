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
```
npm run deployOP
npm run deployFTM
```

## Verify

```
npx hardhat etherscan-verify --network optimism
npx hardhat etherscan-verify --network fantom
```

