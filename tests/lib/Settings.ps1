param(
    [Parameter(Mandatory = $true)]
    $SDK
)

New-Module -Name SDK.Settings -ScriptBlock {
    param(
        [Parameter(Mandatory = $true)]
        $SDK
    )

    $mod = @{ SDK = $SDK }

    Import-Module powershell-yaml -ErrorAction Stop
    . "$PSScriptRoot\helpers\PowerShell.ps1"

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
        Virtualization = {
            return $this.Load("vm.config.yaml")
        }
    }

    $SDK.Extend("Settings", $Settings)

    # Export nothing. This module only modifies the SDK object.
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force