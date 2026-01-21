param(
    [Parameter(Mandatory = $true)]
    $SDK
)

New-Module -Name SDK.Builder -ScriptBlock {
    param(
        [Parameter(Mandatory = $true)]
        $SDK
    )

    Import-Module powershell-yaml -ErrorAction Stop
    . "$PSScriptRoot\helpers\PowerShell.ps1"
    . "$PSScriptRoot\helpers\Config.ps1"

    $mod = @{ SDK = $SDK }

    Add-ScriptProperties $Builder @{
        Name = {
            return $mod.SDK.Settings.Virtualization.Builder.Name
        }
        Runner = {
            return $mod.SDK.Settings.Virtualization.Runner.Name
        }
    }

    Add-ScriptMethods $Builder @{
        Flush = {
            $builder_name = $this.Name
            $runner_name = $this.Runner

            @(
                $builder_name,
                $runner_name
            ) | ForEach-Object {
                $exists = $mod.SDK.Multipass.Exists($_)
                if( -not $exists ) { return }

                $shutdown_called_successfully = $mod.SDK.Multipass.Shutdown($_, $true)
                if( -not $shutdown_called_successfully ) {
                    throw "Failed to shutdown VM '$_'"
                }
                $timed_out = $mod.SDK.Multipass.UntilShutdown($_, 60)
                if( $timed_out ) {
                    throw "Timed out waiting for VM '$_' to shutdown"
                }
                $mod.SDK.Multipass.Destroy($_)
            }
        }
    }

    $SDK.Extend("Builder", $Builder)

    # Export nothing. This module only modifies the SDK object.
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force