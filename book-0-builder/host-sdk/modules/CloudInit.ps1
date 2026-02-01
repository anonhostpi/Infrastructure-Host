param(
    [Parameter(Mandatory = $true)]
    $SDK
)

New-Module -Name SDK.CloudInit -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }

    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $CloudInit = New-Object PSObject

    Add-ScriptMethods $CloudInit @{
        Build = {
            param([int]$Layer)
            $artifacts = $mod.SDK.Builder.Artifacts
            if ($artifacts -and $artifacts.cloud_init -and (Test-Path $artifacts.cloud_init)) {
                $mod.SDK.Log.Info("Cloud-init artifact exists, skipping build")
                return $artifacts
            }
            $mod.SDK.Log.Info("Building cloud-init for layer $Layer...")
            if (-not $mod.SDK.Builder.Build($Layer)) { throw "Failed to build cloud-init for layer $Layer" }
            $artifacts = $mod.SDK.Builder.Artifacts
            if (-not $artifacts -or -not $artifacts.cloud_init) { throw "No cloud-init artifact found." }
            return $artifacts
        }
        Worker = {
            param([int]$Layer, [hashtable]$Overrides = @{})
            $artifacts = $this.Build($Layer)
            $baseConfig = $mod.SDK.Settings.Virtualization.Runner
            $config = @{}; foreach ($k in ($baseConfig.Keys | ForEach-Object { $_ })) { $config[$k] = $baseConfig[$k] }
            $config.CloudInit = "$($mod.SDK.Root())/$($artifacts.cloud_init)"
            foreach ($k in ($Overrides.Keys | ForEach-Object { $_ })) { $config[$k] = $Overrides[$k] }
            return $mod.SDK.Multipass.Worker(@{ Config = $config })
        }
        Cleanup = {
            param([string]$Name)
            if (-not $Name) { $Name = $mod.SDK.Settings.Virtualization.Runner.Name }
            if ($mod.SDK.Multipass.Exists($Name)) { $mod.SDK.Multipass.Destroy($Name) }
        }
        Clean = {
            return $mod.SDK.Builder.Clean()
        }
    }

    $SDK.Extend("CloudInit", $CloudInit)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
