# Review: Network.Shell Method

## Issue

Worker.Shell calls ssh directly instead of using a Network helper method.

```powershell
# Current Worker.Shell
Shell = {
    $keyPath = $mod.SDK.Settings.KeyPath
    & ssh -i $keyPath -p $this.SSHPort -o StrictHostKeyChecking=no "$($this.SSHUser)@$($this.SSHHost)"
}
```

## Fix

Add Network.Shell method mirroring SSH signature, then update Worker.Shell to use it.

### Network.Shell (new)

```powershell
Shell = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Username,
        [Parameter(Mandatory = $true)]
        [string]$Address,
        [int]$Port = 22,
        [string]$KeyPath = $mod.SDK.Settings.KeyPath
    )
    # Key path resolution (same as SSH)
    # Interactive shell (no BatchMode, no Command)
    & ssh @params
}
```

### Worker.Shell (updated)

```powershell
Shell = {
    $mod.SDK.Network.Shell($this.SSHUser, $this.SSHHost, $this.SSHPort)
}
```
