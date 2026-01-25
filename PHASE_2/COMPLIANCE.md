# Compliance Guide

This guide describes how to set up and manage a task list when implementing a `PLAN.md`.

**Reference:** `PHASE_2/RULES.md`

---

## Task List Setup

When starting implementation of a `PLAN.md`, create a task list as follows:

### 1. Initial Review Task

The **first task** must always be:

```
Review RULES.md - initial review before starting
```

### 2. Commit Tasks

Create **one task per commit** in the plan. Format:

```
Commit <N>: <file> - <description>, in compliance with RULES.md
```

Examples:
- `Commit 1: renderer.py - Add fragment discovery function, in compliance with RULES.md`
- `Commit 18: Create Logger.ps1 - module shape, in compliance with RULES.md`

### 3. Review Checkpoints

Insert a review checkpoint **every 10 commits**:

```
Review RULES.md - checkpoint after commit <N>
```

Place these after commits 10, 20, 30, 40, 50, etc.

### 4. Complete Task List Structure

```
1. Review RULES.md - initial review before starting
2. Commit 1: ...
3. Commit 2: ...
...
11. Commit 10: ...
12. Review RULES.md - checkpoint after commit 10
13. Commit 11: ...
...
```

---

## Splitting Commits

If a planned commit exceeds 20 lines of code (Rule 2 violation), **split it**.

### Update the Task List

Replace the single commit task with lettered sub-tasks:

**Before:**
```
Commit 3: renderer.py - Update render_scripts, in compliance with RULES.md
```

**After:**
```
Commit 3a: renderer.py - Update render_scripts signature, in compliance with RULES.md
Commit 3b: renderer.py - Update render_scripts loop logic, in compliance with RULES.md
Commit 3c: renderer.py - Update render_scripts return value, in compliance with RULES.md
```

### Update the Plan

Add a note to the `PLAN.md` documenting the split:

```markdown
### Commit 3a: `renderer.py` - Update render_scripts signature

> **Split from Commit 3** - original exceeded 20 lines

```diff
...
```

### Commit 3b: `renderer.py` - Update render_scripts loop logic

```diff
...
```
```

### Split Strategies

| Strategy | When to Use |
|----------|-------------|
| **Depth-based** | New modules: commit shape first, then add methods |
| **Logical grouping** | Related lines that form a coherent unit |
| **Sequential flow** | Changes that must happen in order |

**Depth-based example (preferred for new modules):**
```
Commit 18a: Create Logger.ps1 - module shape (empty skeleton)
Commit 18b: Logger.ps1 - Add Write method
Commit 18c: Logger.ps1 - Add level methods (Debug, Info, Warn, Error)
```

---

## Redesigning Commits

If a commit's approach is fundamentally wrong, **redesign it**.

### Minor Redesign

If the change is small, update the task description:

**Before:**
```
Commit 5: Config.ps1 - Replace fragment list, in compliance with RULES.md
```

**After:**
```
Commit 5: Config.ps1 - Update fragment names in mapping, in compliance with RULES.md
```

### Major Redesign

If the change requires multiple new commits:

1. Mark the original task as completed with a note
2. Insert new tasks with the original number + letter suffix

**Before:**
```
Commit 5: Config.ps1 - Replace fragment system, in compliance with RULES.md
```

**After:**
```
Commit 5: [REDESIGNED - see 5a-5d]
Commit 5a: Config.ps1 - Add new fragment discovery, in compliance with RULES.md
Commit 5b: Config.ps1 - Update layer mappings, in compliance with RULES.md
Commit 5c: Config.ps1 - Remove old fragment list, in compliance with RULES.md
Commit 5d: Config.ps1 - Update cache initialization, in compliance with RULES.md
```

### Update the Plan

Document the redesign in `PLAN.md`:

```markdown
### Commit 5: [REDESIGNED]

> Original approach was incompatible with existing cache structure.
> Split into Commits 5a-5d below.

### Commit 5a: `Config.ps1` - Add new fragment discovery
...
```

---

## Pre-Commit Verification

Before **every commit**, verify Rule 2 compliance:

```bash
git diff --cached --numstat | awk '!/\.md$/{print $1+$2, $3}'
```

Check that no code file exceeds 20 lines changed.

If verification fails:
1. `git reset HEAD` to unstage
2. Split the changes into smaller commits
3. Update the task list with `##a,b,c` notation
4. Re-stage and verify each smaller commit

---

## Task Completion Flow

For each commit task:

1. **Mark as in_progress** before starting
2. **Make the code change** (5-20 lines max)
3. **Stage the change** with `git add`
4. **Verify compliance** with the pre-commit check
5. **Commit** with descriptive message
6. **Mark as completed** immediately after commit

For review tasks:

1. **Mark as in_progress**
2. **Re-read RULES.md** completely
3. **Verify recent commits** followed the rules
4. **Mark as completed**

---

## Example: Full Task List

```
1.  [pending] Review RULES.md - initial review before starting
2.  [pending] Commit 1: renderer.py - Add discover_fragments, in compliance with RULES.md
3.  [pending] Commit 2: renderer.py - Update create_environment, in compliance with RULES.md
4.  [pending] Commit 3: renderer.py - Update get_environment, in compliance with RULES.md
5.  [pending] Commit 4a: renderer.py - Update render_scripts signature, in compliance with RULES.md
6.  [pending] Commit 4b: renderer.py - Update render_scripts body, in compliance with RULES.md
7.  [pending] Commit 5: renderer.py - Update render_script, in compliance with RULES.md
...
12. [pending] Review RULES.md - checkpoint after commit 10
...
```

Note: Commit 4 was split into 4a and 4b because the original exceeded 20 lines.
