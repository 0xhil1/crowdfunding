## Simple CrowdFunding using Foundry

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```
![Screenshot 2024-07-31 at 4 43 53 AM](https://github.com/user-attachments/assets/2dad6fd3-0bae-4bb1-b93b-b0aec849f15e)

### Deployment

Create .env from .env.example and update the values then run:

```shell
$ forge script --chain sepolia script/DeployCrowdFunding.sol:DeployCrowdFunding --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
```


### Deployed addresses on Sepolia

Sepolia: [0x27841cd89E9996c6AD39D3f772fE637F4C7A4622](https://sepolia.etherscan.io/address/0x27841cd89E9996c6AD39D3f772fE637F4C7A4622)