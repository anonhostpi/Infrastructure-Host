# Review: SDK.Extend Enhancement

## Add Optional Target Parameter

**Proposal**: Update `SDK.Extend` to accept optional third argument for target object.

---

### Current Implementation

```powershell
Extend = {
    param([string]$ModuleName, $ModuleObject)
    $this | Add-Member -MemberType NoteProperty -Name $ModuleName -Value $ModuleObject -Force
}
```

---

### Proposed Implementation

```powershell
Extend = {
    param([string]$ModuleName, $ModuleObject, $Target = $this)
    $Target | Add-Member -MemberType NoteProperty -Name $ModuleName -Value $ModuleObject -Force
}
```

---

## NoteProperty Instances (Submodule Candidates)

| File | Line | Current Usage | Candidate? |
|------|------|---------------|------------|
| SDK.ps1 | 32 | `$this \| Add-Member ... $ModuleName` | Base impl |
| AutoinstallTest.ps1 | 27 | `$SDK.Autoinstall \| Add-Member ... Test` | **Yes** |
| CloudInitTest.ps1 | 27 | `$SDK.CloudInit \| Add-Member ... Test` | **Yes** |
| Verifications.ps1 | 195 | `$SDK.Testing \| Add-Member ... Verifications` | **Yes** |
| Multipass.ps1 | 63 | `$this \| Add-Member ... Rendered` | No (caching) |
| Vbox.ps1 | 45 | `$this \| Add-Member ... Rendered` | No (caching) |

---

## Usage After Change

Submodules would use:
```powershell
$SDK.Extend("Test", $TestObject, $SDK.CloudInit)
$SDK.Extend("Verifications", $VerificationsObject, $SDK.Testing)
```
