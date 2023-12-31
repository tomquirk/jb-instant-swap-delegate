# instant-swap-delegate 🔁

A Juicebox protocol `pay` delegate for automating treasury token swaps.

👉 See it in action: https://goerli.juicebox.money/v2/p/1097

## Proof of functionality

| Contract                                         | Network | Address                                      |
| ------------------------------------------------ | ------- | -------------------------------------------- |
| Deployer                                         | goerli  | `0x0f83918C187585E6343Ac438E2110eFd3000141A` |
| Example delegate (WETH => METH, JB project 1097) | goerli  | `0x7061a10560B1716a19C982E53c64e06C71beFA8c` |

Example `pay` transaction using JBPaySplitDelegate: https://goerli.etherscan.io/tx/0xf5cfea90c5b9c96e9241b24d602d488ccfbe6ec12fc26a67c694ff701bcd27f9

### How to verify it works

1. Note balance of $METH for [`0x0028C35095D34C9C8a3bc84cB8542cB182fcfa8e`](https://goerli.etherscan.io/address/0x0028C35095D34C9C8a3bc84cB8542cB182fcfa8e) ([Project #1097](https://goerli.juicebox.money/v2/p/1097) owner)
2. Pay [Project #1097](https://goerli.juicebox.money/v2/p/1097).
3. Note balance of $METH for [`0x0028C35095D34C9C8a3bc84cB8542cB182fcfa8e`](https://goerli.etherscan.io/address/0x0028C35095D34C9C8a3bc84cB8542cB182fcfa8e) again. It should be higher than the first amount recorded in Step 1.

### What

JBPaySplitDelegate is a `pay` delegate for the Juicebox protocol. It swaps a specified portion of a Juicebox project payment to a specified token (using Uniswap), and sends the proceeds to the Juicebox project owner.

### Why

Juicebox project owners often need to keep some amount of ERC20's in their wallet for operational expenses. For example, a Juicebox project might need $USDC to pay its Infura bill, or $GRT to pay for TheGraph expenses.

[Peel](https://juicebox.money/@peel) is one such project.

Currently, this is a manual process. The project owner (often a multisig e.g. Safe) must reserve some ETH for themselves as a payout and submit a transaction to swap ETH for the desired token. This is time-consuming, especially is a multisig scenario that requires multiple signatures.

JBPaySplitDelegate automates this process.

### Who's it for

Any Juicebox project that needs to keep a balance of particular ERC20 token (for opex or otherwise).

#### Example usage

A project owner might use to swap 10% of every payment their project receives to USDC. This ensures they always have some USDC on hand for expenses.

A project owner could also use JBPaySplitDelegate to dollar-cost-average out of ETH to a given token.

### Future development

While developing this project, I realized that JBPaySplitDelegate could be made far more flexible.

Instead of swapping a single token with a single beneficiary (the project owner), why not mimic the core Juicebox Splits feature?

JBPaySplitDelegate could define various split types, for example:

- ETHSplit: divert some of the ETH payment to some address
- TokenSplit: swap some of the payment to a given token

Then, each split could have a different beneficiary type:

- `owner`: transfer portion of payment to the project owner
- `project`: transfer portion of payment to another Juicebox project
- `address`: transfer portion of payment to a given Ethereum address

#### Client and app support

It's simple for clients to support JBPaySplitDelegate. If a Juicebox project has its funding cycle datasource set to a JBPaySplitDelegate, then the client can show:

- how much of their payment is going to the Juicebox project treasury
- how much of their payment is going to the project owner
- the tokens being swapped

#### Gas concerns

The Juicebox Core contracts are optimized for payments to incur as least gas as possible. Makes sense!

Payments to Juicebox projects with this delegate will cost more gas. This might be undesirable for the payer.

Giving users the option to opt out of this might be an option (for example, using a checkbox).

## Development

Dependencies:

- Foundry installed and updated ([Learn how to install Foundry](https://book.getfoundry.sh/getting-started/installation))
- Yarn ([Learn how to use Yarn](https://classic.yarnpkg.com/en/docs/install))

1. Install dependencies

   ```bash
   yarn install
   ```

   Note: the `preinstall` script will run `forge install` for you.

### Usage

use `yarn test` to run tests

use `yarn test:fork` to run tests in CI mode (including slower mainnet fork tests)

use `yarn size` to check contract size

use `yarn doc` to generate natspec docs

use `yarn lint` to lint the code

use `yarn tree` to generate a Solidity dependency tree

use `yarn deploy:mainnet` and `yarn deploy:goerli` to deploy and verify (see .env.example for required env vars, using a ledger by default).

Run `yarn coverage`to display code coverage summary and generate an LCOV report

## Ack

Thanks to https://github.com/jbx-protocol/juice-buyback for showing me the wei initially.
