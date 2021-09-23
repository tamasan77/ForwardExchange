# Forward Exchange
A platform to create customizable decentralized forward contracts, with some properties of futures contracts.

Unlike traditional forward contracts ,this platform minimizes risks by
requiring the long and short parties to commit a collateral.
Additionally, similarly to futures contracts the two account are marked to market periodically.

For the forward contract users can select any underlying asset by agreeing on an API to use, margin requirements, what collateral token to use and the expiration date of the forward contract.

# Component Architecture
![Component Diagram](https://github.com/tamasan77/ForwardExchange/blob/main/docs/Component%20Diagram.jpg?raw=true)

### Personal Wallet
The Personal Wallet holds ERC20 tokens that the owner of the wallet can use to allocate allowances to be used by the Collateral Wallet. 
The Personal Wallet Factory holds the addressess of all the Personal Wallets and can create new personal wallets with a given owner.

### Collateral Wallet
The Collateral Wallet is used to hold pledged collateral(ERC20), and is used to keep track 
of changes in the balances of long and short parties of forward contracts. The Collateral Wallet Factory can 
be used to create Collateral Wallets.

### Oracle
The oracle component is used to make get requests to various APIs with custom parameters
in order to get real-time date on the price of underlying assets, risk free rate and to make a 
call to the valuation API for the price of the forward contract.

### Forward
The Forward Factory is used to deploy customized Forward Contracts.
The Forward Contract smart contract contain all necessary functionalities that 
are needed during the life-cycle of the forward, including *Initiation*, *Mark to Market*, *Default* and *Settlement*.

