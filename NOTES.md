# Notes

### Scripts used to launch:
```
forge script script/DeployNFT1155.s.sol:DeployNFT1155 --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/DeployNFT721.s.sol:DeployNFT721 --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/DeployNFT6909.s.sol:DeployNFT721 --rpc-url $RPC_URL --broadcast --verify -vvvv

forge script script/FactoryDeploy.s.sol:FactoryDeployScript --rpc-url $RPC_URL --broadcast --verify
forge script script/MarketplaceDeploy.s.sol:MarketplaceDeployScript --rpc-url $RPC_URL --broadcast --verify
```

forge script script/MarketplaceDeploy.s.sol:MarketplaceDeployScript     --rpc-url $RPC_URL     --private-key $PRIVATE_KEY     --broadcast     --verify     --verifier blockscout     --verifier-url $EXPLORER --legacy
RPC_URL=
EXPLORER=
PRIVATE_KEY=***

