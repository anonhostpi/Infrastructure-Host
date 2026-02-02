# Feedback #4: Consolidate Add-ScriptMethods Calls

**Baseline commit:** `05924d7`

## Request

Files that use `Add-ScriptMethods` without a Worker setup between calls should have their calls consolidated into a single call. Multipass.ps1 and Vbox.ps1 are excluded because they have Worker setup interspersed between calls.

## Files to Consolidate

| File | Current Calls | Reason |
|------|--------------|--------|
| Testing.ps1 | 5 → 1 | No Worker setup |
| Autoinstall.ps1 | 4 → 1 | No Worker setup |
| CloudInit.ps1 | 3 → 1 | No Worker setup |
| Logger.ps1 | 2 → 1 | No Worker setup |
| Fragments.ps1 | 2 → 1 | No Worker setup |
| Builder.ps1 | 2 → 1 | Worker setup is before both calls, not between |

## Additional Change

- Builder.ps1: Rename `RegisterRunner` to `Register` (no callers found)

## Excluded Files

| File | Reason |
|------|--------|
| Multipass.ps1 | Worker setup between Add-ScriptMethods calls |
| Vbox.ps1 | Worker setup between Add-ScriptMethods calls |
| Worker.ps1 | Inner call is on different object ($Target) inside method body |

## Approach

Each consolidation is a deletion-only change: remove the `}`, blank line, and `Add-ScriptMethods $X @{` separators between consecutive calls. The method bodies stay exactly as-is.

For Builder.ps1, also rename `RegisterRunner` → `Register` in the same commit.
