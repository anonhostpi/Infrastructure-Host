param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Autoinstall -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Autoinstall = New-Object PSObject

    Add-ScriptMethods $Autoinstall @{
        Worker = {
            param([hashtable]$Overrides = @{})
            $artifacts = $mod.SDK.Builder.Artifacts
            if (-not $artifacts -or -not $artifacts.iso) { throw "No ISO artifact found. Build the ISO first." }
            $baseConfig = $mod.SDK.Settings.Virtualization.Vbox
            $config = @{}; foreach ($k in ($baseConfig.Keys | ForEach-Object { $_ })) { $config[$k] = $baseConfig[$k] }
            $config.IsoPath = $artifacts.iso
            foreach ($k in ($Overrides.Keys | ForEach-Object { $_ })) { $config[$k] = $Overrides[$k] }
            return $mod.SDK.Vbox.Worker(@{ Config = $config })
        }
    }

    Add-ScriptMethods $Autoinstall @{
        Build = {
            param([int]$Layer)
            $artifacts = $mod.SDK.Builder.Artifacts
            if ($artifacts -and $artifacts.iso -and (Test-Path $artifacts.iso)) {
                $mod.SDK.Log.Info("ISO artifact exists, skipping build")
                return $artifacts
            }
            $mod.SDK.Log.Info("Building ISO for layer $Layer...")
            if (-not $mod.SDK.Builder.Build($Layer)) { throw "Failed to build for layer $Layer" }
            # ISO build is triggered separately via make iso
            return $mod.SDK.Builder.Artifacts
        }
    }

    Add-ScriptMethods $Autoinstall @{
        Cleanup = {
            param([string]$Name)
            if (-not $Name) { $Name = $mod.SDK.Settings.Virtualization.Vbox.Name }
            if ($mod.SDK.Vbox.Exists($Name)) { $mod.SDK.Vbox.Destroy($Name) }
        }
    }

    Add-ScriptMethods $Autoinstall @{
        Clean = {
            return $mod.SDK.Builder.Clean()
        }
    }

    $SDK.Extend("Autoinstall", $Autoinstall)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
