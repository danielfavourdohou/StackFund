# StackFund: Decentralized Crowdfunding Platform on Stacks

StackFund is a transparent, decentralized crowdfunding platform built on the Stacks blockchain. It allows creators to launch campaigns with funding goals and deadlines, while backers can pledge STX tokens to support projects they believe in.

## Project Overview

Traditional crowdfunding platforms involve high fees, centralized control, and lack of transparency. StackFund solves these problems with a blockchain-based approach:

- **Transparent & Trustless**: All funds and campaign rules operate through smart contracts
- **Lower Fees**: Platform fees are capped at 5-10% instead of 20-30% on traditional platforms
- **Backer Rewards**: Successful campaign backers receive special tokens recognizing their early support
- **Automatic Refunds**: If campaigns don't reach their goals, backers receive automatic refunds
- **Decentralized Governance**: Admin controls are transparent and limited to necessary functions

## Architecture

![StackFund Architecture](https://via.placeholder.com/800x400?text=StackFund+Architecture)

### Contract Structure

StackFund is built with a modular contract architecture:

1. **interface.clar**: Public interfaces and convenience methods for frontend interactions
2. **campaign-core.clar**: Core business logic for campaign management (create, pledge, finalize, refund)
3. **campaign-state.clar**: Data structures and state management for campaigns
4. **backer-token.clar**: NFT implementation for backer recognition and rewards
5. **admin-and-fees.clar**: Platform administration and fee management
6. **math-utils.clar**: Safe math operations and calculation utilities
7. **time-utils.clar**: Time and block-related utilities

## Setup Instructions

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js (v16+) and npm

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/stackfund.git
   cd stackfund
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Run Clarinet checks:
   ```bash
   clarinet check
   ```

4. Run tests:
   ```bash
   clarinet test
   ```

## Usage Examples

### Create a Campaign

```clarity
(contract-call? .campaign-core create-campaign 
  "My Awesome Project" 
  "This is a game-changing application for Stacks" 
  u100000000 ;; 100 STX goal
  u1440 ;; ~10 days (assuming 10-minute blocks)
)
```

### Pledge to a Campaign

```clarity
(contract-call? .campaign-core pledge 
  u1 ;; Campaign ID
  u10000000 ;; 10 STX pledge
)
```

### Finalize a Campaign

Once the deadline has passed, anyone can trigger finalization:

```clarity
(contract-call? .campaign-core finalize-campaign u1)
```

### Request a Refund

If a campaign doesn't reach its goal, backers can request refunds:

```clarity
(contract-call? .campaign-core refund u1)
```

### Mint a Backer Token

For successful campaigns, claim your backer token:

```clarity
(contract-call? .campaign-core mint-backer-token u1)
```

## UI Integration

The sample UI component included demonstrates how to integrate with the StackFund contracts using React and Tailwind CSS. To use it:

1. Install required packages:
   ```bash
   npm install @stacks/connect-react @stacks/transactions
   ```

2. Configure your contract address in the component
3. Import and use the `StackFundCampaigns` component in your React application

## Contributing

We welcome contributions to StackFund! Here's how to get started:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Run tests: `clarinet test`
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Contribution Guidelines

- Ensure `clarinet check` passes with no errors
- Write tests for new functionality
- Follow Clarity best practices for security and efficiency
- Update documentation for any changed functionality

## Future Enhancements

- Token-gated campaigns (require specific tokens to participate)
- Milestone-based funding release
- Enhanced backer rewards and governance
- Multi-token support (SIP-010 tokens)
- DAO integration for community-driven platform decisions

## License

This project is licensed under the MIT License - see the LICENSE file for details.