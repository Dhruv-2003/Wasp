# Wasp Contracts

 
 ## CLM Order 
 
 - `contracts/waspMaster` : Handles all the functions for the user to interact with the Wasp Architecture. Create the CLM Order and register the Upkeeps
 - `contracts/waspWallet` :  User wallet/ portfolio for the CLM Orders , stores the users funds and handles the trade execution and othe logic

## DCA Order

- `contracts/dcaMaster` : Entrypoint for placing the DCA Orders , handles the streams for the user and stores order data
- `contracts/dcaWallet` : DCA wallet holding the user funds  until they are unwraped and swapped for DCA asset .

## Range Order

- `contracts/rangeMaster` : Entrypoint for a range orders , create the TPF order , and responsible for creating new rangeWallets
- `contracts/rangeWallet` : Holds the user funds for the range orders , handles the asset swapping , and also for minting the liquidity position in the range Price 
