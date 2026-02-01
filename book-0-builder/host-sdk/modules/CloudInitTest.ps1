param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.CloudInit.Test -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $CloudInitTest = New-Object PSObject

    Add-ScriptMethods $CloudInitTest @{
        Run = {
            param([int]$Layer, [hashtable]$Overrides = @{}, $Runner = $null)
            if (-not $Runner) {
                $config = $mod.SDK.Settings.Virtualization.Runner
                foreach ($k in ($Overrides.Keys | ForEach-Object { $_ })) { $config[$k] = $Overrides[$k] }
                $Runner = $mod.SDK.Builder.Runner($config, "Multipass", $Layer)
            }
            $mod.SDK.Testing.Reset()
            $mod.SDK.Testing.Verifications.Run($Runner, $Layer, 2)
            $mod.SDK.Testing.Summary()
            return @{ Success = ($mod.SDK.Testing.FailCount -eq 0); Results = $mod.SDK.Testing.Results; Worker = $Runner }
        }
    }

    $mod.SDK.Extend("Test", $CloudInitTest, $mod.SDK.CloudInit)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
