# Plan: HOST-SDK Refactoring Implementation

## Overview

Implement changes from review documents:
- REVIEW.CLEANUP.md - Fix Invoke-*.ps1 API paths
- REVIEW.EXTEND.md - Add $Target parameter to SDK.Extend
- REVIEW.AUTOINSTALL.md - Merge GetArtifacts into Worker
- REVIEW.LAYERS.md - Add SDK.Settings.Layers
- REVIEW.WORKER.md - Consolidate Worker module

---

## Commits by Review Document

### REVIEW.EXTEND.md (1 commit)

1. **SDK.ps1**: Add $Target parameter to Extend method

### REVIEW.LAYERS.md (2 commits)

2. **Settings.ps1**: Add Layers property from build_layers.yaml
3. **Fragments.ps1**: Use SDK.Settings.Layers instead of direct load

### REVIEW.CLEANUP.md (2 commits)

4. **Invoke-AutoinstallTest.ps1**: Fix API paths (AutoinstallTest → Autoinstall.Test)
5. **Invoke-IncrementalTest.ps1**: Fix API paths (CloudInitTest → CloudInit.Test)

### REVIEW.AUTOINSTALL.md (2 commits)

6. **Autoinstall.ps1**: Merge GetArtifacts into Worker, rename CreateWorker → Worker
7. **AutoinstallTest.ps1**: Update to use Autoinstall.Worker()

### REVIEW.WORKER.md - Core Changes (8 commits)

8. **Network.ps1**: Add SCP method
9. **Worker.ps1**: Rewrite with Methods approach (Ensure, Test, UntilInstalled, Errored, Status, Setup, Pull, Push, Shell)
10. **General.ps1**: Delete file
11. **SDK.ps1**: Remove General.ps1 loading
12. **Multipass.ps1**: Update to use $mod.SDK.Worker.Methods()
13. **Multipass.ps1**: Remove UntilInstalled from core module
14. **Multipass.ps1**: Remove UntilInstalled, Status, Setup from $mod.Worker.Methods
15. **Vbox.ps1**: Update to use $mod.SDK.Worker.Methods()

### REVIEW.WORKER.md - CreateWorker Renames (2 commits)

16. **CloudInit.ps1**: Rename CreateWorker → Worker
17. **CloudInitTest.ps1**: Update to use CloudInit.Worker()

### REVIEW.EXTEND.md - Submodule Updates (3 commits)

18. **AutoinstallTest.ps1**: Use SDK.Extend with $Target parameter
19. **CloudInitTest.ps1**: Use SDK.Extend with $Target parameter
20. **Verifications.ps1**: Use SDK.Extend with $Target parameter

### PR Finalization (2 commits)

21. **PHASE_2/BOOK_0/**: Delete REVIEW.*.md files (completed)
22. **PR**: Update PR description with implementation summary

---

## Implementation Order Rationale

1. **Extend first** - Enables submodule pattern for later commits
2. **Layers** - Independent, low risk
3. **Cleanup** - Fix broken scripts early
4. **Autoinstall** - GetArtifacts merge before Worker consolidation
5. **Worker core** - Major refactoring
6. **CreateWorker renames** - After Worker.ps1 stabilized
7. **Submodule updates** - Use new SDK.Extend signature
8. **PR finalization** - Clean up review docs, update PR

---

## Files Modified

| File | Commits |
|------|---------|
| SDK.ps1 | 1, 11 |
| Settings.ps1 | 2 |
| Fragments.ps1 | 3 |
| Invoke-AutoinstallTest.ps1 | 4 |
| Invoke-IncrementalTest.ps1 | 5 |
| Autoinstall.ps1 | 6 |
| AutoinstallTest.ps1 | 7, 18 |
| Network.ps1 | 8 |
| Worker.ps1 | 9 |
| General.ps1 | 10 (delete) |
| Multipass.ps1 | 12, 13, 14 |
| Vbox.ps1 | 15 |
| CloudInit.ps1 | 16 |
| CloudInitTest.ps1 | 17, 19 |
| Verifications.ps1 | 20 |
| REVIEW.*.md | 21 (delete) |
