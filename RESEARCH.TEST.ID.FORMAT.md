---
topic: TEST.ID.FORMAT
branch: feat/test-id-format
status: in-progress
---

# Research: Structured Test Context (book/layer/fragment)

## Problem

Legacy test IDs use flat strings (e.g. `"base::packages::apt"`) that are manually
constructed and do not align with the SDK's metadata system. This makes test output
harder to correlate with playbook structure and requires maintenance whenever
book/layer/fragment names change.

## Goal

Replace flat test ID strings with structured context objects sourced from the SDK's
metadata system, using a consistent `book / layer / fragment` hierarchy that mirrors
the actual playbook layout.

## References

- Closes #20
