param(
    [Parameter(Mandatory = $true)]
    $SDK
)

New-Module -Name SDK.General -ScriptBlock {
    param(
        [Parameter(Mandatory = $true)]
        $SDK
    )

    $mod = @{ SDK = $SDK }

    . "$PSScriptRoot\helpers\PowerShell.ps1"

    $General = New-Object PSObject

    Add-ScriptMethods $General @{
        UntilInstalled = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Username,
                [Parameter(Mandatory = $true)]
                [string]$Address,
                [int]$Port = 22,
                [int]$TimeoutSeconds = 900 # 15 minutes
            )

            return $mod.SDK.Network.SSH(
                $mod.SDK.Settings.KeyPath,
                $Username,
                $Address,
                $Port,
                "cloud-init status --wait",
                $TimeoutSeconds
            ).Success
        }
        Errored = {
            $status = $mod.SDK.Network.SSH(
                $mod.SDK.Settings.KeyPath,
                $Username,
                $Address,
                $Port,
                "cloud-init status"
            ).Output

            $joined = $status -join " "
            $errored = $joined -match "status: error" -or $joined -match "status: degraded"

            if ($errored) {
                Write-Host "  Cloud-init finished with errors" -ForegroundColor Yellow
                return $true
            }
            return $false
        }
    }

    $SDK.Extend("General", $General)
    
    # Export nothing. This module only modifies the SDK object.
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force