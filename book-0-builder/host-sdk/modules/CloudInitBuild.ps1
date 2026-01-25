param(
    [Parameter(Mandatory = $true)]
    $SDK
)

New-Module -Name SDK.CloudInitBuild -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }

    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $CloudInitBuild = New-Object PSObject

    Add-ScriptMethods $CloudInitBuild @{
        Build = {
            param([int]$Layer)
            $mod.SDK.Log.Info("Building cloud-init for layer $Layer...")
            if (-not $mod.SDK.Builder.Build($Layer)) { throw "Failed to build cloud-init for layer $Layer" }
            $artifacts = $mod.SDK.Builder.Artifacts
            if (-not $artifacts -or -not $artifacts.cloud_init) { throw "No cloud-init artifact found." }
            return $artifacts
        }
        CreateWorker = {
            param([int]$Layer, [hashtable]$Overrides = @{})
            $artifacts = $this.Build($Layer)
            $baseConfig = $mod.SDK.Settings.Virtualization.Runner
            $config = @{}; foreach ($k in $baseConfig.Keys) { $config[$k] = $baseConfig[$k] }
            $config.CloudInit = "$($mod.SDK.Root())/$($artifacts.cloud_init)"
            foreach ($k in $Overrides.Keys) { $config[$k] = $Overrides[$k] }
            return $mod.SDK.Multipass.Worker(@{ Config = $config })
        }
    }

    $SDK.Extend("CloudInitBuild", $CloudInitBuild)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
