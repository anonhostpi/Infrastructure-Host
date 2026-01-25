param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Testing.Verifications -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Verifications = New-Object PSObject

    Add-ScriptMethods $Verifications @{
        Fork = {
            param([string]$Test, [string]$Decision, [string]$Reason = "")
            $msg = "[FORK] $Test : $Decision"
            if ($Reason) { $msg += " ($Reason)" }
            $mod.SDK.Log.Debug($msg)
        }
    }

    Add-ScriptMethods $Verifications @{
        Run = {
            param($Worker, [int]$Layer)
            $methods = @{
                1 = "Network"; 2 = "Kernel"; 3 = "Users"; 4 = "SSH"; 5 = "UFW"
                6 = "System"; 7 = "MSMTP"; 8 = "PackageSecurity"; 9 = "SecurityMonitoring"
                10 = "Virtualization"; 11 = "Cockpit"; 12 = "ClaudeCode"
                13 = "CopilotCLI"; 14 = "OpenCode"; 15 = "UI"
                16 = "PackageManagerUpdates"; 17 = "UpdateSummary"; 18 = "NotificationFlush"
            }
            foreach ($l in 1..$Layer) {
                if ($methods.ContainsKey($l)) {
                    $methodName = $methods[$l]
                    if ($this.PSObject.Methods[$methodName]) {
                        $this.$methodName($Worker)
                    }
                }
            }
        }
    }

    # Verification methods added in following commits

    $SDK.Testing | Add-Member -MemberType NoteProperty -Name Verifications -Value $Verifications
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
