# Phase 2: Content Updates Index

This directory contains per-section Phase 2 plans generated from `TEMPLATE.md`.

---

## Sections

### Book 0 - Builder Layer

| Directory | Section                      | Status |
| --------- | ---------------------------- | ------ |
| `BOOK_0/` | book-0-builder (entire book) | [ ]    |

### Book 1 - Foundation Layer

| Directory      | Path                   | Status |
| -------------- | ---------------------- | ------ |
| `BOOK_1_BASE/` | book-1-foundation/base | [ ]    |

### Book 2 - Cloud Layer Fragments

| Directory                | Path                        | Status |
| ------------------------ | --------------------------- | ------ |
| `BOOK_2_NETWORK/`        | book-2-cloud/network        | [ ]    |
| `BOOK_2_KERNEL/`         | book-2-cloud/kernel         | [ ]    |
| `BOOK_2_USERS/`          | book-2-cloud/users          | [ ]    |
| `BOOK_2_SSH/`            | book-2-cloud/ssh            | [ ]    |
| `BOOK_2_UFW/`            | book-2-cloud/ufw            | [ ]    |
| `BOOK_2_SYSTEM/`         | book-2-cloud/system         | [ ]    |
| `BOOK_2_MSMTP/`          | book-2-cloud/msmtp          | [ ]    |
| `BOOK_2_PACKAGES/`       | book-2-cloud/packages       | [ ]    |
| `BOOK_2_PKG_SECURITY/`   | book-2-cloud/pkg-security   | [ ]    |
| `BOOK_2_SECURITY_MON/`   | book-2-cloud/security-mon   | [ ]    |
| `BOOK_2_VIRTUALIZATION/` | book-2-cloud/virtualization | [ ]    |
| `BOOK_2_COCKPIT/`        | book-2-cloud/cockpit        | [ ]    |
| `BOOK_2_CLAUDE_CODE/`    | book-2-cloud/claude-code    | [ ]    |
| `BOOK_2_COPILOT_CLI/`    | book-2-cloud/copilot-cli    | [ ]    |
| `BOOK_2_OPENCODE/`       | book-2-cloud/opencode       | [ ]    |
| `BOOK_2_UI/`             | book-2-cloud/ui             | [ ]    |
| `BOOK_2_PKG_UPGRADE/`    | book-2-cloud/pkg-upgrade    | [ ]    |

---

## Generation Order

Recommended order for generating Phase 2 docs:

1. **Book 0** - SDKs first (other sections depend on these paths)
2. **Book 1 / base** - Foundation (required, others may reference)
3. **Book 2 required fragments** - network, users, ssh
4. **Book 2 optional fragments** - Remaining in build_order

---

## Cross-Cutting Concerns

These items affect multiple sections and should be tracked separately:

- [ ] **Makefile updates** - New paths, targets for fragment discovery
- [ ] **pyproject.toml updates** - Package paths if needed
- [ ] **.gitignore updates** - Config patterns per new structure
- [ ] **Root README** - Overview of new structure

---

## Progress Summary

- Total sections: 19
- Completed: 0
- In Progress: 0
- Not Started: 19
