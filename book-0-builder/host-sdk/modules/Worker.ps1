param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Worker -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Worker = New-Object PSObject

    Add-ScriptMethods $Worker @{
        Methods = {
            param($Target)
            Add-ScriptMethods $Target @{
                Ensure = {
                    if (-not $this.Exists()) { return $this.Create() }
                    return $true
                }
                RecordTest = {
                    param(
                        [bool]$Pass,
                        [string]$TestId,
                        [string]$Name,
                        $Output,
                        $Error
                    )
                    # WIP: body implemented in next commit
                }
                Test = {
                    param([string]$TestId, [string]$Name, [string]$Command, $ExpectedPattern)
                    $mod.SDK.Log.Debug("Running test: $Name")
                    try {
                        $result = $this.Exec($Command)
                        $joined = $result.Output -join "`n"
                        if ($ExpectedPattern -is [scriptblock]) {
                            $pass = $result.Success -and (& $ExpectedPattern $joined)
                        } else {
                            $pass = $result.Success -and ($joined -match $ExpectedPattern)
                        }
                        $ctx = $mod.SDK.Testing.Context
                        $label = "$($ctx.Book) - $($ctx.Layer) - $($ctx.Fragment) - $Name"
                        $testResult = @{ Test = $TestId; Book = $ctx.Book; Layer = $ctx.Layer; Fragment = $ctx.Fragment; Name = $Name; Pass = $pass; Output = $result.Output; Error = $result.Error }
                        $mod.SDK.Testing.Record($testResult)
                        if ($pass) { $mod.SDK.Log.Write("[PASS] $label", "Green") }
                        else { $mod.SDK.Log.Write("[FAIL] $label", "Red"); if ($result.Error) { $mod.SDK.Log.Error("  Error: $($result.Error)") } }
                        return $testResult
                    }
                    catch {
                        $ctx = $mod.SDK.Testing.Context
                        $label = "$($ctx.Book) - $($ctx.Layer) - $($ctx.Fragment) - $Name"
                        $mod.SDK.Log.Write("[FAIL] $label - Exception: $_", "Red")
                        $testResult = @{ Test = $TestId; Book = $ctx.Book; Layer = $ctx.Layer; Fragment = $ctx.Fragment; Name = $Name; Pass = $false; Error = $_.ToString() }
                        $mod.SDK.Testing.Record($testResult)
                        return $testResult
                    }
                }
                UntilInstalled = {
                    param([int]$TimeoutSeconds = 900)
                    return $this.Exec("cloud-init status --wait").Success
                }
                Errored = {
                    $status = $this.Exec("cloud-init status").Output
                    $joined = $status -join " "
                    $errored = $joined -match "status: error" -or $joined -match "status: degraded"
                    if ($errored) {
                        $mod.SDK.Log.Warn("Cloud-init finished with errors")
                        return $true
                    }
                    return $false
                }
                Status = {
                    $result = $this.Exec("cloud-init status")
                    return $result.Output
                }
                Setup = {
                    param([bool]$FailOnNotInitialized)
                    $created = $this.Ensure()
                    if (-not $created) {
                        throw "Failed to create VM '$($this.Name)'"
                    }
                    $initialized = $this.UntilInstalled()
                    if (-not $initialized -and $FailOnNotInitialized) {
                        throw "Cloud-init failed for VM '$($this.Name)'"
                    }
                    return $initialized
                }
                Pull = {
                    param([string]$RemotePath, [string]$LocalPath)
                    return $mod.SDK.Network.SCP(
                        $this.SSHUser, $this.SSHHost, $this.SSHPort,
                        $LocalPath, $RemotePath, "Pull"
                    ).Success
                }
                Push = {
                    param([string]$LocalPath, [string]$RemotePath)
                    return $mod.SDK.Network.SCP(
                        $this.SSHUser, $this.SSHHost, $this.SSHPort,
                        $LocalPath, $RemotePath, "Push"
                    ).Success
                }
                Exec = {
                    param([string]$Command)
                    return $mod.SDK.Network.SSH($this.SSHUser, $this.SSHHost, $this.SSHPort, $Command)
                }
                Shell = {
                    $mod.SDK.Network.Shell($this.SSHUser, $this.SSHHost, $this.SSHPort)
                }
            }
        }
    }

    $SDK.Extend("Worker", $Worker)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
