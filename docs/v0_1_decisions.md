# ReBudget v0.1 decision record

**Status:** accepted
**Scope:** iOS-first, single-user, fully offline personal bookkeeping. No account, cloud sync, AI, investments, account balances, or statement import.

This record turns the initial product requirements into stable implementation rules. Changes require a new dated entry in this document and a data-migration review.

## Product rules

- A transaction always has a positive amount in fen, a kind (`income` or `expense`), a local payment date, and one category of the same kind. A child category is optional.
- Expense nature is `regular` or `special`; it is not applicable to income. Budget and regular-spend analytics exclude special expenses.
- Categories are two levels at most. Existing referenced categories/tags are archived instead of deleted. A transaction may have zero or more tags.
- Reporting weeks use ISO weeks (Monday–Sunday). A reporting month is the device-local calendar month and is stored as `YYYY-MM`.
- Money is stored as integer CNY fen; floating-point money is forbidden. Amount input supports at most two decimals.
- Business dates are stored as `YYYY-MM-DD`; creation/update audit timestamps are UTC ISO-8601 strings.
- A future budget copies the preceding month only when no budget exists for the requested month, and never overwrites edits. v0.1 category budgets are top-level expense category budgets.
- Recurring bills generate a pending instance when the app starts, resumes, or opens the recurring-bill screen. Missed periods are backfilled. Skipping resolves only that instance; it does not deactivate the template.
- A recurring confirmation creates one cash transaction. Allocation rows drive attribution reporting: no allocation creates one row in the payment month; even allocation starts in the payment month; remainder fen goes to the earliest months.
- Automatic review figures are live calculations. Only the user's monthly summary and next-month plan are saved.

## Architecture decision

The app uses Flutter feature folders, Riverpod for app state, and one local SQLite database accessed through `sqflite`. SQLite is the only persistent source of truth. The first delivery implements the vertical slice needed for manual transactions and category/tag analysis; budgets, recurring bills, and reviews follow the same database/migration conventions.

## Database evolution

Every schema version has an explicit upgrade path and a fixture migration test. Schema changes are additive first; destructive changes require copy/backfill/swap migration in a transaction. Seed categories are inserted only into an empty category table and never overwrite user data.

## Delivery update: period and hot-tag analytics

The initial usable release includes manual income/expense recording, category breakdowns, and tag aggregation. Category and tag rankings use regular expenses only and support current ISO week, current calendar month, current calendar year, and all-time ranges. A tag total is deliberately not a partition: a transaction with two tags contributes its full amount to both tag aggregates, because tags describe independent spending contexts. Each ranked row opens the matching local ledger entries for auditability.
