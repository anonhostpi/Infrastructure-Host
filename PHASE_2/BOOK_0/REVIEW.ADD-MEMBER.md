# Review: Add-Member Usage

## Findings

| File | Line | Usage | Status |
|------|------|-------|--------|
| SDK.ps1:33 | `$Target \| Add-Member -MemberType NoteProperty` | SDK.Extend implementation | OK |
| PowerShell.ps1:104 | `$target \| Add-Member -MemberType ScriptMethod` | Inside Add-ScriptMethods helper | OK |
| PowerShell.ps1:125 | `$target \| Add-Member -MemberType ScriptProperty` | Inside Add-ScriptProperties helper | OK |
| Fragments.ps1:13 | `$Fragments \| Add-Member -MemberType ScriptProperty -Name Layers` | **Should use Add-ScriptProperty** | FIX |
| Multipass.ps1:63 | `$this \| Add-Member -MemberType NoteProperty -Name Rendered` | Caching pattern inside getter | OK |
| Vbox.ps1:45 | `$this \| Add-Member -MemberType NoteProperty -Name Rendered` | Caching pattern inside getter | OK |

## Fix Required

**Fragments.ps1:13** - Replace direct Add-Member with Add-ScriptProperty helper.

```powershell
# Before
$Fragments | Add-Member -MemberType ScriptProperty -Name Layers -Value { ... }

# After
Add-ScriptProperty $Fragments @{
    Layers = { ... }
}
```
