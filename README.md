# Quorum Checker Smart Contract

A decentralized governance smart contract for managing proposals and voting with quorum verification. This contract is designed to facilitate decision-making processes in a transparent and efficient manner, ensuring that a minimum level of participation (quorum) is met before decisions are finalized.

---

## Features

- **Governance Voting**: Allows members to create proposals and vote on them.
- **Quorum Verification**: Ensures that a minimum percentage of members participate in voting.
- **Proposal Management**: Create, track, and close proposals with detailed information.
- **Member Management**: Supports up to 100 members with customizable quorum thresholds.
- **Error Handling**: Provides clear error codes for common governance scenarios.
- **Read-Only Functions**: Query proposals, votes, and member status without modifying the contract state.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Contract Details](#contract-details)
3. [Functions](#functions)
   - [Initialization Functions](#initialization-functions)
   - [Proposal Management Functions](#proposal-management-functions)
   - [Voting Functions](#voting-functions)
   - [Quorum Verification Functions](#quorum-verification-functions)
   - [Member Management Functions](#member-management-functions)
   - [Utility Functions](#utility-functions)
4. [Error Codes](#error-codes)
5. [License](#license)

---

## Getting Started

### Prerequisites

- **Stacks Blockchain**: Ensure you have a Stacks node or testnet environment set up.
- **Clarity Language**: Familiarity with Clarity smart contracts is recommended.

### Deployment

1. Clone this repository:
   ```bash
   git clone https://github.com/your-username/Quorum-checker.git
   cd Quorum-checker
   ```

2. Deploy the contract using the Stacks CLI:
   ```bash
   clarinet deploy
   ```

3. Interact with the contract using the provided public functions.

---

## Contract Details

- **Owner**: The contract owner is initialized as the deployer and has special permissions.
- **Members**: A list of up to 100 principals who can participate in governance.
- **Quorum Threshold**: A percentage (e.g., 51%) that defines the minimum participation required for a proposal to be valid.

---

## Functions

### Initialization Functions

- **`(initialize (new-members (list 100 principal)) (threshold uint))`**  
  Initializes the contract with a list of members and a quorum threshold. Can only be called once by the contract owner.

### Proposal Management Functions

- **`(create-proposal (title (string-utf8 256)) (description (string-utf8 500)) (voting-period uint))`**  
  Allows members to create proposals with a title, description, and voting period.

- **`(close-proposal (proposal-id uint))`**  
  Closes a proposal, marking it as no longer active.

### Voting Functions

- **`(vote (proposal-id uint) (vote-for bool))`**  
  Allows members to cast their vote (yes or no) on a proposal.

### Quorum Verification Functions

- **`(is-quorum-met (proposal-id uint))`**  
  Checks if the quorum threshold is met for a specific proposal.

- **`(get-quorum-info)`**  
  Returns details about the quorum threshold, total members, and required votes.

- **`(votes-needed-for-quorum (proposal-id uint))`**  
  Calculates the number of votes needed to meet the quorum for a proposal.

### Member Management Functions

- **`(get-members)`**  
  Returns the list of all members.

- **`(is-member (principal-to-check principal))`**  
  Checks if a given principal is a member.

### Utility Functions

- **`(get-proposal (proposal-id uint))`**  
  Retrieves details of a specific proposal.

- **`(get-total-proposals)`**  
  Returns the total number of proposals created.

- **`(get-proposal-status (proposal-id uint))`**  
  Provides the status of a proposal, including quorum and participation details.

---

## Error Codes

| Code | Description                          |
|------|--------------------------------------|
| 100  | Caller is not the contract owner.    |
| 101  | Invalid quorum threshold.            |
| 102  | Contract already initialized.        |
| 103  | Quorum not met.                      |
| 104  | Caller is not a member.              |
| 105  | Member has already voted.            |
| 106  | Voting period is closed.             |
| 107  | Proposal not found.                  |

---

## License

This project is licensed under the [MIT License](LICENSE).

Developed by [Your Name or Organization]. Contributions and feedback are welcome!
```
