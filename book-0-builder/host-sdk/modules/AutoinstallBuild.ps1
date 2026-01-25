param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.AutoinstallBuild -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $AutoinstallBuild = New-Object PSObject

    Add-ScriptMethods $AutoinstallBuild @{
        GetArtifacts = {
            $artifacts = $mod.SDK.Builder.Artifacts
            if (-not $artifacts -or -not $artifacts.iso) { throw "No ISO artifact found. Build the ISO first." }
            return $artifacts
        }
        CreateWorker = {
            param([hashtable]$Overrides = @{})
            $artifacts = $this.GetArtifacts()
            $baseConfig = $mod.SDK.Settings.Virtualization.Vbox
            $config = @{}; foreach ($k in $baseConfig.Keys) { $config[$k] = $baseConfig[$k] }
            $config.IsoPath = $artifacts.iso
            foreach ($k in $Overrides.Keys) { $config[$k] = $Overrides[$k] }
            return $mod.SDK.Vbox.Worker(@{ Config = $config })
        }
    }

    Add-ScriptMethods $AutoinstallBuild @{
        Cleanup = {
            param([string]$Name)
            if (-not $Name) { $Name = $mod.SDK.Settings.Virtualization.Vbox.Name }
            if ($mod.SDK.Vbox.Exists($Name)) { $mod.SDK.Vbox.Destroy($Name) }
        }
    }

    $SDK.Extend("AutoinstallBuild", $AutoinstallBuild)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
