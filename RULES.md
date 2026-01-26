# Implementation Rules

These rules govern the complete workflow from discovery through implementation.

---

## Rule 0: Discovery & Design

Before planning implementation, you will explore and design the solution.

**Process:**

1. User tasks you with analyzing a problem or feature
2. Create analysis and design documents exploring the solution space
3. Documents may include: current state analysis, proposed changes, trade-offs, dependencies
4. Iterate with user feedback until the approach is clear
5. When user approves the design, proceed to **Rule 1**

**Document characteristics:**

- Exploratory and descriptive
- May contain diffs for illustration, but `PLAN.md` holds the **authoritative diffs**
- May contain multiple options or alternatives
- Should identify files to modify and rough scope
- Serves as input for creating the formal plan

---

## Rule 1: Plan Before You Commit

**[Requires user approval]** Before transitioning from Rule 0 (discovery/design) to Rule 1 (commit planning), you must get explicit user approval. Do not begin writing commits to `PLAN.md` until the user confirms they are ready to move from brainstorming to implementation planning.

You will create or update a `PLAN.md` for every change you plan to make.

- `PLAN.md` will be an annotated diff containing every change you want to make **before** making them
- `PLAN.md` contains the **authoritative diffs** - discovery documents may have illustrative diffs, but `PLAN.md` is canonical
- The purpose of Rule 1 is to pre-emptively prevent Rule 3 violations
- When **coming from Rule 6** (code review cycle), **append** new commits to the existing `PLAN.md`

**Format:**

````markdown
# Plan: <brief description>

## Files to Modify

### Commit N: `path/to/file.py` - <description>

```diff
- old line
+ new line
```

Reason: <why this change>
````

**When to update PLAN.md for existing commits:**

If a planned commit becomes invalid during implementation (stale, nonsensical, or exceeds line limit), see **Rule 4** for how to split or redesign it. This applies only to commits already in the plan that need correction—not to new commits added via Rule 6.

---

## Rule 2: Task List Creation

After creating `PLAN.md`, create a task list to track implementation progress.

**Process:**

1. Create one task per commit in the plan
2. Add RULES.md review checkpoints every 10 commits
3. The first task must be "Review RULES.md - initial review before starting"

**Task format:**

```
Commit <N>: <file> - <description>, in compliance with RULES.md
```

**See "Task List Setup" section below for complete structure and examples.**

---

## Rule 3: Microcommits Only

Your commits must be microcommits.

**Restrictions:**

- Changes are restricted to **5-20 lines per commit** for code files
- You may have more than one file with 5-20 lines each, but you should **minimize this**
- If a planned commit no longer makes sense or is stale, see **Rule 4** for redesign procedures

**Exemptions (no line limit):**

- File deletions
- File renames/moves
- Markdown files (`.md`)

---

## Rule 4: Pre-Commit Verification & Splitting

This rule governs validation, splitting, and `PLAN.md` maintenance for **existing planned commits**.

### Verification

Run this command before every commit to verify Rule 3 compliance:

```bash
git diff --cached --numstat -M | awk '
  /\.md$/ { next }                           # Skip markdown files
  /=>/ { next }                              # Skip renames/moves (detected by -M)
  $1 == 0 { next }                           # Skip pure deletions
  {
    lines = $1 + $2
    print lines, $3
    sum += lines
    if ($2 == 0 && $1 > 0) { newfiles = newfiles $3 "\n" }
  }
  END {
    if (sum > 20) {
      msg = "---\nValidation failed. Commit exceeds line limit (" sum " lines).\n"
      msg = msg "Are you sure this is the smallest commit size?\n"
      msg = msg "Can you break this into smaller commits?\n"
      msg = msg "- reference Rule 4 from RULES.md"
      if (length(newfiles) > 0) {
        msg = msg "\n\nNew file(s) detected:\n" newfiles
        msg = msg "\nWas this (these) supposed to be a move/rename?\n"
        msg = msg "- If yes: investigate why git did not detect it (use git diff -M)\n"
        msg = msg "- If move + contribution: split into 2 commits per Rule 4 (move first, then contribute)"
      }
      print msg > "/dev/stderr"
      exit 1
    }
  }
'
```

**What this validates:**
- Counts lines changed in code files (excludes `.md`)
- Exempts file deletions (no line limit)
- Exempts file renames/moves (detected via `-M` flag)
- If a new file addition fails validation, prompts to check if it should have been a rename

If the command exits with an error, the commit is too large.

### On Successful Verification

When a commit passes verification and is committed:

1. **Mark the commit as complete in `PLAN.md`** by adding a status indicator
2. Proceed to the next commit

**Example PLAN.md update:**

```markdown
### Commit 3: `renderer.py` - Update loop logic [COMPLETE]
```

### On Failed Verification (Exceeds Line Limit)

If verification fails due to exceeding 20 lines:

1. `git reset HEAD` to unstage
2. Split the changes into smaller commits (see Splitting Commits below)
3. **Update `PLAN.md`** to document the split
4. Re-stage and verify each smaller commit

### On Stale or Nonsensical Commits

If a planned commit no longer applies or doesn't make sense:

1. Do not attempt the commit
2. **Update `PLAN.md`** to mark the commit as redesigned
3. Add new commit entries with the original number + letter suffix
4. Continue with the redesigned commits

---

### Splitting Commits

When splitting is required, **always prefer depth-wise splitting over length-wise splitting**.

#### Why Depth-Wise?

Large commits typically exceed the line limit because of **closures** (blocks like `{ ... }`, scriptblocks, function bodies, class definitions). Splitting by line count often breaks logical units. Instead, split by **depth**:

1. **First commit**: Create the outer shape with a placeholder
2. **Following commits**: Add depth to the enclosed block

#### Depth-Wise Splitting Example (PowerShell)

A 45-line scriptblock was staged:

```powershell
Add-ScriptMethods $Object @{
    Method1 = {
        # 15 lines of logic
    }
    Method2 = {
        # 12 lines of logic
    }
    Method3 = {
        # 10 lines of logic
    }
}
```

**Wrong (length-wise):** Split at line 20, breaking Method1 mid-body.

**Correct (depth-wise):**

```
Commit 5a: Object.ps1 - Add method block shape
```
```powershell
Add-ScriptMethods $Object @{
    Method1 = {
        # WIP
    }
    Method2 = {
        # WIP
    }
    Method3 = {
        # WIP
    }
}
```

```
Commit 5b: Object.ps1 - Implement Method1
Commit 5c: Object.ps1 - Implement Method2
Commit 5d: Object.ps1 - Implement Method3
```

The `# WIP` placeholder can be replaced with other shape lines (parameter declarations, return statements) if the commit stays under the line limit.

#### Step 1: Update `PLAN.md`

Document the split with lettered sub-commits:

```markdown
### Commit 5: [SPLIT - see 5a-5d]

> Original exceeded 20 lines due to closure depth. Split into shape + implementations.

### Commit 5a: `Object.ps1` - Add method block shape

```diff
+Add-ScriptMethods $Object @{
+    Method1 = {
+        # WIP
+    }
+    Method2 = {
+        # WIP
+    }
+    Method3 = {
+        # WIP
+    }
+}
```

### Commit 5b: `Object.ps1` - Implement Method1

```diff
     Method1 = {
-        # WIP
+        param($Arg)
+        # actual implementation
+        return $result
     }
```

#### Step 2: Update Task List

Replace the single commit task with lettered sub-tasks:

**Before:**
```
Commit 5: Object.ps1 - Add methods, in compliance with RULES.md
```

**After:**
```
Commit 5a: Object.ps1 - Add method block shape, in compliance with RULES.md
Commit 5b: Object.ps1 - Implement Method1, in compliance with RULES.md
Commit 5c: Object.ps1 - Implement Method2, in compliance with RULES.md
Commit 5d: Object.ps1 - Implement Method3, in compliance with RULES.md
```

#### Split Strategies Summary

| Strategy | When to Use | Priority |
|----------|-------------|----------|
| **Depth-based** | Closures, blocks, nested structures | **Preferred** |
| **Logical grouping** | Related lines that form a coherent unit | Secondary |
| **Sequential flow** | Changes that must happen in order | Secondary |

---

### Redesigning Commits

When a commit approach is fundamentally wrong:

#### Minor Redesign

Update the task description and `PLAN.md` entry:

**Before:**
```
Commit 5: Config.ps1 - Replace fragment list
```

**After:**
```
Commit 5: Config.ps1 - Update fragment names in mapping
```

#### Major Redesign

If the change requires multiple new commits:

**Update `PLAN.md`:**
```markdown
### Commit 5: [REDESIGNED]

> Original approach was incompatible with existing cache structure.
> Split into Commits 5a-5d below.

### Commit 5a: `Config.ps1` - Add new fragment discovery
...
```

**Update task list:**
```
Commit 5: [REDESIGNED - see 5a-5d]
Commit 5a: Config.ps1 - Add new fragment discovery, in compliance with RULES.md
Commit 5b: Config.ps1 - Update layer mappings, in compliance with RULES.md
Commit 5c: Config.ps1 - Remove old fragment list, in compliance with RULES.md
Commit 5d: Config.ps1 - Update cache initialization, in compliance with RULES.md
```

---

## Rule 5: Branch and PR Workflow

Each significant work unit should have an associated implementation branch.

**Branch naming:** Use a descriptive prefix:
- `feature/<name>` - New functionality
- `refactor/<name>` - Code restructuring
- `fix/<name>` - Bug fixes

**Workflow:**

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

**Note:** If the user performs a code review at any point, proceed to **Rule 6**.

---

## Rule 6: Code Review Cycle

When the user performs a code review and requests changes:

1. **Create a review document** capturing the requested changes
2. **Return to Rule 0** - treat the review feedback as a new discovery/design task
3. Iterate through Rule 0 until the approach is clear
4. **Proceed to Rule 1** - **append** new commits to the existing `PLAN.md`
5. Continue through Rules 3-5 with the new commits

**Important:** Rule 6 adds **new commits** to address review feedback. It does not modify, split, or redesign existing commits—that's Rule 4's domain. The review cycle flows through Rule 0 → Rule 1 (append) → Rule 2 → Rule 3 → Rule 4 → Rule 5.

**Review document characteristics:**

- Captures specific feedback from the code review
- Identifies what needs to change and why
- May contain illustrative diffs (authoritative diffs go in `PLAN.md`)
- May propose solutions or alternatives
- Serves as input for the appended plan

**PLAN.md append format:**

```markdown
---

## Code Review Changes (Review #1)

### Commit 57: `Network.ps1` - Fix WaitForSSH duplication

```diff
...
```

Reason: Code review identified redundant method.

This cycle can repeat multiple times until the PR is approved.

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

## Task Completion Flow

For each commit task:

1. **Mark as in_progress** before starting
2. **Make the code change** (5-20 lines max)
3. **Stage the change** with `git add`
4. **Verify compliance** with the pre-commit check (Rule 4)
5. **Commit** with descriptive message
6. **Mark as completed** in task list immediately after commit
7. **Mark as completed** in `PLAN.md` (Rule 4)

For review tasks:

1. **Mark as in_progress**
2. **Re-read RULES.md** completely
3. **Verify recent commits** followed the rules
4. **Mark as completed**

---

## Workflow Summary

```
┌───────────────────────────────────────────────────────────────────────┐
│                                                                       │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐        │
│  │  Rule 0  │───▶│  Rule 1  │───▶│  Rule 2  │───▶│  Rule 3  │        │
│  │ Discovery│    │   Plan   │    │  Tasks   │    │ Micro-   │        │
│  │ & Design │    │          │    │          │    │ commits  │        │
│  └──────────┘    └──────────┘    └──────────┘    └────┬─────┘        │
│       ▲                                               │               │
│       │                                               ▼               │
│       │                                         ┌──────────┐         │
│       │                                         │  Rule 4  │         │
│       │                                         │ Verify & │         │
│       │                                         │  Split   │         │
│       │                                         └────┬─────┘         │
│       │                                               │               │
│       │                                               ▼               │
│       │                                         ┌──────────┐         │
│       │                                         │  Rule 5  │         │
│       │                                         │ Branch & │         │
│       │                                         │    PR    │         │
│       │                                         └────┬─────┘         │
│       │                                               │               │
│       │                   ┌──────────┐               │               │
│       └───────────────────│  Rule 6  │◀──────────────┘               │
│              (append)     │  Review  │   (if review requested)       │
│                           │  Cycle   │                               │
│                           └──────────┘                               │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

---

## Rationale

Rules 0-4 exist to minimize review load and ensure thoughtful implementation.

**Rule 0** ensures we understand the problem before committing to a solution.

**Rules 1-4** ensure commits are planned, tracked, and reviewable:

| Change Type | Naturally Digestible? | Microcommit Required? |
| ----------- | --------------------- | --------------------- |
| File deletion | Yes | No |
| File rename/move | Yes | No |
| Markdown files | Yes | No |
| Any code change | No | **Yes** |

Commits are not PRs. A commit should take **less than 5 seconds** to review. If understanding a commit takes more than a minute, the commit sucks.

- **File operations** are human-readable because content doesn't matter - only the path
- **Documentation** is human-readable by design
- **Source code** is not human-readable - changes must be small and obvious

**Rule 6** ensures code review feedback is handled with the same rigor as initial implementation, cycling back through the full workflow to append new commits.

---

## Example: Full Task List

```
1.  [completed] Review RULES.md - initial review before starting
2.  [completed] Commit 1: renderer.py - Add discover_fragments
3.  [completed] Commit 2: renderer.py - Update create_environment
4.  [in_progress] Commit 3: renderer.py - Update get_environment
5.  [pending] Commit 4a: renderer.py - Add method block shape
6.  [pending] Commit 4b: renderer.py - Implement first method
7.  [pending] Commit 4c: renderer.py - Implement second method
8.  [pending] Commit 5: renderer.py - Update render_script
...
13. [pending] Review RULES.md - checkpoint after commit 10
...
```

Note: Commit 4 was split into 4a-4c using depth-wise splitting because the original exceeded 20 lines due to nested closures.
