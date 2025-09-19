ERC20 Token Project
Overview
This project implements a custom ERC20 token using Solidity and Foundry. The contract includes standard ERC20 functionality such as minting, burning, transferring tokens, and handling approvals, with comprehensive tests to ensure correctness and security.
Features

Minting: Authorized users can mint new tokens.
Burning: Users can burn their tokens to reduce supply.
Transfers: Supports transfer, transferFrom, and approve for secure token movement.
Events: Emits Transfer and Approval events for transparency.
Tests: Thorough test suite covering all functions and edge cases (e.g., insufficient balance, invalid addresses).

Prerequisites

Foundry (install: curl -L https://foundry.paradigm.xyz | bash)
Git
Solidity ^0.8.0
OpenZeppelin Contracts (used for ERC20 base implementation)

Installation

Clone the repository:git clone https://github.com/psalmsprint/erc20-token.git
cd erc20-token


Install dependencies:forge install


Build the project:forge build



Usage

Run tests:forge test


Deploy to a testnet (e.g., Sepolia):forge create --rpc-url <your-rpc-url> --private-key <your-private-key> src/ERC20Token.sol:ERC20Token

Replace <your-rpc-url> and <your-private-key> with your testnet details.

Project Structure

src/ERC20Token.sol: Main ERC20 contract.
test/ERC20Token.t.sol: Test suite for all functionality.
foundry.toml: Foundry configuration.
.gitmodules: Submodule dependencies (e.g., OpenZeppelin).

Testing
The test suite includes:

Minting and burning tokens.
Transfer and approval functionality.
Edge cases: zero-address transfers, insufficient balance, and unauthorized actions.

Run forge test -vv for detailed test output.
Future Improvements

Add role-based access control for minting.
Optimize gas usage in transfer functions.
Integrate with a front-end for user interaction.

Author

psalmsprint
Built as part of a 12-week Web3 roadmap to master smart contract development.

License
MIT License
