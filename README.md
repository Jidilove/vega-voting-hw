# Vega Voting Homework

## Overview
This project implements a voting protocol based on a specialized ERC20 token VV.

Users can:
- receive VV tokens
- stake VV for 1 to 4 weeks
- gain voting power based on the formula:
  VP_U(t) = sum_i (T_expiry - t)^2 * A_i
- vote yes/no in active votings

Admin can:
- create votings
- pause/unpause the protocol
- mint VV to users

When a vote is finalized, an ERC721 NFT is minted to store voting results.

## Contracts
- VVToken (ERC20)
- VotingResultNFT (ERC721)
- VegaVoting

## Tech stack
- Solidity 0.8.24
- Foundry
- OpenZeppelin v5
- Sepolia

## Commands
```bash
forge build
forge test -vv
```
