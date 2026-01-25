param(
    [Parameter(Mandatory = $true)]
    $SDK
)

New-Module -Name SDK.Settings -ScriptBlock {
    param(
        [Parameter(Mandatory = $true)]
        $SDK
    )

    . "$PSScriptRoot\helpers\PowerShell.ps1"
    . "$PSScriptRoot\helpers\Config.ps1"

    $mod = @{
        SDK = $SDK
        BuildConfig = Build-TestConfig
        VirtConfig = $null
    }

    function ConvertTo-PascalCase {
        param([string]$Name)
        return ($Name -split '[-_]' | ForEach-Object {
            if ($_.Length -gt 0) { $_.Substring(0,1).ToUpper() + $_.Substring(1) } else { '' }
        }) -join ''
    }

    $Settings = New-Object PSObject -Property @{
        KeyPath = "~/.ssh/id_ed25519.pub"
    }

    Add-ScriptMethods $Settings @{
        Load = {
            param(
                [Parameter(Mandatory = $true)]
                [string] $Path
            )

            $source = @(
                $Path,
                "$($mod.SDK.Root())/$Path"
            ) | Where-Object { Test-Path $_ } | Resolve-Path | Select-Object -First 1

            if( $null -eq $source ) {
                throw "Settings file '$Path' not found."
            }
            $content = Get-Content -Path $source -Raw
            return $content | ConvertFrom-Yaml
        }
    }

    $mod.VirtConfig = $Settings.Load("vm.config.yaml")

    Add-ScriptProperties $Settings @{
        Virtualization = {
            return $mod.VirtConfig
        }
    }

    # Build dynamic properties for each config key
    # Properties use PascalCase (e.g., $SDK.Settings.Identity for 'identity' config)
    $keys = $mod.BuildConfig.Keys | ForEach-Object { $_ }
    $methods = @{}

    foreach( $key in $keys ) {
        $configGetter = ConvertTo-PascalCase $key
        $src = @(
            "",
            "`$configOriginal = '$key'",
            {
                return $mod.BuildConfig[$configOriginal]
            }.ToString(),
            ""
        ) -join "`n"
        $sb = iex "{ $src }"
        $methods[$configGetter] = $sb
    }
    Add-ScriptProperties $Settings $methods

    $SDK.Extend("Settings", $Settings)

    # Export nothing. This module only modifies the SDK object.
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force