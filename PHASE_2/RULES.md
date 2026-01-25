# Implementation Rules

These rules govern commit behavior and restrictions.

---

## Rule 1: Plan Before You Commit

You will create or update a `PLAN.md` for every change you plan to make.

- `PLAN.md` will be an annotated diff containing every change you want to make **before** making them
- The purpose of Rule 1 is to pre-emptively prevent Rule 2 violations

**Format:**

````markdown
# Plan: <brief description>

## Files to Modify

### `path/to/file.py`

```diff
- old line
+ new line
```

Reason: <why this change>
````

---

## Rule 2: Microcommits Only

Your commits must be microcommits.

**Restrictions:**

- Changes are restricted to **5-20 lines per commit** for code files
- You may have more than one file with 5-20 lines each, but you should **minimize this**

**Exemptions (no line limit):**

- File deletions
- File renames/moves
- Markdown files (`.md`)

---

## Rule 3: Pre-Commit Verification

You will run this command before every commit to verify Rule 2 compliance:

```bash
git diff --cached --numstat | awk '!/\.md$/{print $1+$2, $3; sum+=$1+$2} END{print "---\nTotal:", sum}' && echo "This commit violates Rule 2 of RULES.md by exceeding 20 lines. Commits of this size are unacceptable. Please try to split your changes into smaller microcommits that are compliant with RULES.md." >&2 && exit 1
```

This is **not** a git hook - it is a manual verification step you must perform before every commit.

---

## Rule 4: Branch and PR Workflow

For each folder in `PHASE_2/`, you will have an associated implementation branch.

**Branch naming:** `phase2/<book-name>` (e.g., `phase2/book-0`, `phase2/book-2-network`)

**Workflow for each item:**

1. Complete implementation on branch
2. **[Requires user approval]** Create `PR.md` detailing the changes
3. **[Requires user approval]** Submit PR to GitHub using `gh` CLI
4. **[Requires user approval]** Merge with **merge commit** (to track original PR number)

**PR.md:**

- Located in repository root (untracked)
- Removed after PR submission (do not commit)

**Merge command:**

```bash
gh pr merge <PR_NUMBER> --merge --delete-branch
```

---

## Rationale

Rules 1-3 exist to minimize review load.

Commits are not PRs. A commit should take **less than 5 seconds** to review. If understanding a commit takes more than a minute, the commit sucks.

| Change Type | Naturally Digestible? | Microcommit Required? |
| ----------- | --------------------- | --------------------- |
| File deletion | Yes | No |
| File rename/move | Yes | No |
| Markdown files | Yes | No |
| Any code change | No | **Yes** |

This is about human-readability:

- **File operations** are human-readable because content doesn't matter - only the path, which is one line
- **Documentation** is human-readable by design
- **Source code** is not human-readable - changes must be small and obvious in behavior to meet the 5-second goal
