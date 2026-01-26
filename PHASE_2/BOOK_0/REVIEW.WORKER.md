# Review: Worker Module Consolidation

## General.ps1 + Worker.ps1 Merge

**Current State**:
- Worker.ps1 exports a function `Add-CommonWorkerMethods` - should be a module method instead
- General.ps1 methods (`UntilInstalled`, `Errored`) were meant for workers but call `Network.SSH` directly

**Research - $this.Exec Viability**:
- VboxWorker.Exec already uses SSH internally: `$mod.SDK.Network.SSH($this.SSHUser, $this.SSHHost, $this.SSHPort, $Command)`
- MultipassWorker.Exec uses `multipass exec`
- Both return `@{Output; ExitCode; Success}`

**Conclusion**: General.ps1 methods should use `$this.Exec()` instead of `Network.SSH`. This would work for both worker types since each implements Exec appropriately.

**Proposed Changes**:
1. Move General.ps1 methods into Worker.ps1
2. Convert `Add-CommonWorkerMethods` from exported function to module method
3. Update methods to use `$this.Exec("cloud-init status --wait")` instead of `Network.SSH(...)`
4. Delete General.ps1
5. Remove General.ps1 loading from SDK.ps1

---

## CreateWorker → Worker Rename

**Instances to rename** (where "Worker" is not reserved):

| File | Current | Proposed |
|------|---------|----------|
| CloudInit.ps1:28 | `CreateWorker = {` | `Worker = {` |
| CloudInitTest.ps1:13 | `$mod.SDK.CloudInit.CreateWorker(...)` | `$mod.SDK.CloudInit.Worker(...)` |
| Autoinstall.ps1:16 | `CreateWorker = {` | `Worker = {` |
| AutoinstallTest.ps1:13 | `$mod.SDK.Autoinstall.CreateWorker(...)` | `$mod.SDK.Autoinstall.Worker(...)` |

**Reserved** (do not rename):
- `$SDK.Multipass.Worker` - factory method
- `$SDK.Vbox.Worker` - factory method
