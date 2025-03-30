# StacksTrust - Smart Contract

## Overview
The Offspring Will Smart Contract is a decentralized solution built on the Stacks blockchain to facilitate controlled savings for a child under a parent’s supervision. The contract enables the creation of child accounts with locked funds that become accessible after a set maturity period. Additionally, the contract incorporates fees, administrative privileges, and emergency withdrawal functionalities.

## Features
- **Child Account Creation:** Parents can open a child’s account with a set deposit and lock period.
- **Funding Child Accounts:** Additional funds can be deposited after account creation.
- **Maturity-Based Withdrawals:** Children can withdraw funds upon reaching the maturity height.
- **Emergency Withdrawals:** Parents or admins can withdraw funds in case of emergencies.
- **Admin Management:** Parents can assign or remove admins for the child’s account.
- **Fee Management:** Fees are charged for account opening and withdrawals, with earnings withdrawable by the deployer.
- **Security Measures:** Proper authorization checks are enforced before account modifications or withdrawals.

## Contract Constants
| Constant | Description |
|----------|-------------|
| `deployer` | Address of the contract deployer. |
| `contract-address` | The contract's own address. |
| `year-in-block` | Defines the number of blocks in a year. |
| `account-opening-charge` | Fee charged when opening a child account (5 STX). |
| `minimum-initial-deposit` | Minimum deposit required to open an account (5 STX). |
| `withdrawal-fee` | Fee deducted upon normal withdrawals (2%). |
| `emergency-withdrawal-fee` | Fee deducted upon emergency withdrawals (10%). |

## Data Structures
- **Child Account Map:**
  - `parent` - Address of the parent.
  - `child-name` - Name of the child (max 24 ASCII characters).
  - `child-wallet` - Address of the child’s wallet.
  - `unlock-height` - Block height when funds become accessible.
  - `balance` - Current balance in the child’s account.
  - `admins` - List of up to 5 admins who can manage the account.

## Functions
### Read Functions
- `get-contract-balance` - Returns the STX balance of the contract.
- `get-account` - Retrieves details of a specific child account.
- `get-total-fees-earned` - Returns the total fees collected by the contract.

### Public Write Functions
- `create-account` - Opens a child’s account with a specified deposit and lock period.
- `fund-child-account` - Allows additional deposits into a child’s account.
- `child-withdraw` - Enables the child to withdraw their matured funds.
- `replace-child-wallet` - Allows the parent to update the child’s wallet address.
- `emergency-withdraw` - Allows parents or admins to withdraw funds before maturity in emergencies.
- `withdraw-earnings` - Enables the contract deployer to withdraw collected fees.

### Admin Functions
- `add-child-admin` - Allows the parent to add an admin to the child’s account.
- `remove-child-admin` - Allows the parent to remove an admin from the child’s account.

## Usage Example
1. **Creating a Child Account**
   ```clarity
   (create-account "Alice" 'SP123... 5 u10000000)
   ```
2. **Funding a Child Account**
   ```clarity
   (fund-child-account 'SP123... "Alice" u5000000)
   ```
3. **Withdrawing Funds** (After Maturity)
   ```clarity
   (child-withdraw 'SP123... "Alice")
   ```
4. **Emergency Withdrawal**
   ```clarity
   (emergency-withdraw 'SP123... "Alice")
   ```

## Security Considerations
- Only parents or designated admins can modify child accounts.
- Withdrawals before maturity attract higher fees.
- All transactions require sufficient STX balance.
- Unauthorized access attempts are blocked.
