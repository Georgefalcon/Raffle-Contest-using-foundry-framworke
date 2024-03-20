# Provably Random Raffle Contracts

## About
A raffle contract, in the context of blockchain and smart contracts, is a decentralized application (DApp) designed to facilitate and manage raffles or lotteries using blockchain technology.

Here's a basic outline of how a raffle contract might work:

Deployment: The raffle contract is deployed on a blockchain platform such as Ethereum.

Entry: Participants can interact with the contract by sending a transaction to enter the raffle. They may need to send a specific amount of cryptocurrency (such as Ether in the case of Ethereum) as an entry fee.

Random Selection: Once the entry period is over, the contract randomly selects a winner from the pool of participants. The randomness is typically achieved using cryptographic techniques or oracles to ensure fairness and transparency.

Winner Determination: The selected winner is awarded the prize. The contract may automatically transfer the prize funds to the winner's address.

Transparency and Immutability: Since the raffle contract is deployed on a blockchain, all transactions and operations are transparent and immutable, meaning they cannot be altered or tampered with. This ensures that the raffle is fair and free from manipulation.

Raffle contracts can offer several benefits over traditional raffles, including increased transparency, reduced risk of fraud, and automated execution of the raffle process. However, it's essential to consider legal and regulatory implications when deploying and using such contracts, as laws regarding gambling and lotteries vary by jurisdiction. Additionally, users should exercise caution and due diligence when participating in raffles conducted through smart contracts to avoid potential scams or security risks.

## What we want to do
1. User can enter by paying for a ticket
    I. The ticket fees are going to go to the winner during the draw
2. After X period of time, the lottery will automatically draw a winner
    I. This would be done programmatically
3. Using chainlink VRF and chainlink Automation
    I. chainlink VRF -> Randomness
    II. chainlink Automation -> Time based trigger

## Tests
1. Write some deploy scripts
2. Write our test
    I. work on a localchain
    II. Forked testnet
    III. Forked mainnet





