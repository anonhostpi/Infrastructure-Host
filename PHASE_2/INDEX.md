# Phase 2: Content Updates Index

This directory contains per-section Phase 2 plans generated from `TEMPLATE.md`.

---

## Sections

### Book 0 - Builder Layer

| File        | Section                      | Status |
| ----------- | ---------------------------- | ------ |
| `BOOK_0.md` | book-0-builder (entire book) | [ ]    |

### Book 1 - Foundation Layer

| File             | Path                   | Status |
| ---------------- | ---------------------- | ------ |
| `BOOK_1_BASE.md` | book-1-foundation/base | [ ]    |

### Book 2 - Cloud Layer Fragments

| File                       | Path                        | Status |
| -------------------------- | --------------------------- | ------ |
| `BOOK_2_NETWORK.md`        | book-2-cloud/network        | [ ]    |
| `BOOK_2_KERNEL.md`         | book-2-cloud/kernel         | [ ]    |
| `BOOK_2_USERS.md`          | book-2-cloud/users          | [ ]    |
| `BOOK_2_SSH.md`            | book-2-cloud/ssh            | [ ]    |
| `BOOK_2_UFW.md`            | book-2-cloud/ufw            | [ ]    |
| `BOOK_2_SYSTEM.md`         | book-2-cloud/system         | [ ]    |
| `BOOK_2_MSMTP.md`          | book-2-cloud/msmtp          | [ ]    |
| `BOOK_2_PACKAGES.md`       | book-2-cloud/packages       | [ ]    |
| `BOOK_2_PKG_SECURITY.md`   | book-2-cloud/pkg-security   | [ ]    |
| `BOOK_2_SECURITY_MON.md`   | book-2-cloud/security-mon   | [ ]    |
| `BOOK_2_VIRTUALIZATION.md` | book-2-cloud/virtualization | [ ]    |
| `BOOK_2_COCKPIT.md`        | book-2-cloud/cockpit        | [ ]    |
| `BOOK_2_CLAUDE_CODE.md`    | book-2-cloud/claude-code    | [ ]    |
| `BOOK_2_COPILOT_CLI.md`    | book-2-cloud/copilot-cli    | [ ]    |
| `BOOK_2_OPENCODE.md`       | book-2-cloud/opencode       | [ ]    |
| `BOOK_2_UI.md`             | book-2-cloud/ui             | [ ]    |
| `BOOK_2_PKG_UPGRADE.md`    | book-2-cloud/pkg-upgrade    | [ ]    |

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
