# Vega Voting HW2

## Overview
This project implements a voting protocol using Solidity, Foundry and OpenZeppelin.

## Features
- ERC20 token `VV`
- staking with lock period from 1 to 4 weeks
- voting power formula:

  VP_U(t) = sum_i (T_expiry - t)^2 * A_i

- admin-only vote creation
- yes/no voting
- early finalization when threshold is reached
- ERC721 NFT storing voting result

## Contracts
- VVToken — ERC20 token
- VotingResultNFT — ERC721 token for voting results
- VegaVoting — main contract

## Deployment

Network: Sepolia

VegaVoting:
0x757dAc2622bcd9B276fF35f3115a7A4A6C25392A

VV Token:
0x62661Ba3A12469Da24025C79E6D27786296ee6B5

Result NFT:
0x508dc60d0530E4Ab5C4a083Fbc50002b2bFf94Ef

## Participants:
- addr1: https://sepolia.etherscan.io/address/0xBe2b89ADfD578Ef49F7D1a55F5D7Bc63d6446DaC
- addr2: https://sepolia.etherscan.io/address/0xdb938f77E79CC99905eA478FCA45795Bc50C7061

## Demonstration

### Vote 1 (Finalized)
- vote passed
- NFT minted with result

### Vote 2
- two different addresses voted
- both yes and no votes recorded

## Transactions

Deploy:
https://sepolia.etherscan.io/tx/0xdcda034491889c328028bb1a528a1147f2737bcd4d3499951b07c6dea5287a35

Mint VV (addr1):
https://sepolia.etherscan.io/tx/0xb107f1cf8f973dc2327f6481f7a01b1e9f4ce9244116f673e9fb7f2a81b9294d

Mint VV (addr2):
https://sepolia.etherscan.io/tx/0x65f312583a41c762cfbe9f46aac1a36130531e1f846b789dd4aac2d4d618878c

Approve (addr1):
https://sepolia.etherscan.io/tx/0xf338ca43a1d8a9db00d2797f0cde152a3c3537ac74ba816252d483f4a843dd57

Approve (addr2):
https://sepolia.etherscan.io/tx/0x569349a1b22abd916e4f33900ab59aef0137ccb642d8e5a3774132e6c12cbb6f

Stake (addr1):
https://sepolia.etherscan.io/tx/0xcd68736299ae3d8fb012cea17dd4d4e11169a08f23bd09976102ae9dfa03941d

Stake (addr2):
https://sepolia.etherscan.io/tx/0x59ff31cfc93632e2fea43995ff469585ba52bb136b21e81deda5c1b901483f30

Create Vote 1:
https://sepolia.etherscan.io/tx/0xf44c6668ac904e77697ca2bb9551a0fdcb0606b0d8e6ff825101703a2d232ded

Vote 1:
https://sepolia.etherscan.io/tx/0x890a85d7538a155f6f219423504bbd9b4f73aad8a61abb4c80a2af837cac8eeb

Create Vote 2:
https://sepolia.etherscan.io/tx/0x2bc005c6a4fd98b841fc1c8dc1a5275ec66fcdfb1fdb8b3c2f2cfa30b2a08f19

Vote addr1:
https://sepolia.etherscan.io/tx/0xc5169494486ccf09f898251a39d5fa0479159356d93fd4125408034f5202bc4f

Vote addr2:
https://sepolia.etherscan.io/tx/0x1a90af8c29299bddf78c962217394a4ea6b6bacc78ecc29f8f305058a8053152

## Tech stack
- Solidity 0.8.24
- Foundry
- OpenZeppelin
