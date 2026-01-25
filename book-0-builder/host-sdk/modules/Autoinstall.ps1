param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Autoinstall -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Autoinstall = New-Object PSObject

    Add-ScriptMethods $Autoinstall @{
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

    Add-ScriptMethods $Autoinstall @{
        Cleanup = {
            param([string]$Name)
            if (-not $Name) { $Name = $mod.SDK.Settings.Virtualization.Vbox.Name }
            if ($mod.SDK.Vbox.Exists($Name)) { $mod.SDK.Vbox.Destroy($Name) }
        }
    }

    $SDK.Extend("Autoinstall", $Autoinstall)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
