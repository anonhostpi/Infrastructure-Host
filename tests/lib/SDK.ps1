param(
    [switch] $Globalize
)

New-Module -Name SDK -ScriptBlock {
    param(
        [bool] $Globalize = $false
    )

    . "$PSScriptRoot/helpers/PowerShell.ps1"

    $SDK = New-Object PSObject -Property @{
        Path = "$PSScriptRoot\SDK.ps1"
    }

    if ($Globalize) {
        Set-Variable -Name SDK -Value $SDK -Scope Global
    }

    Add-ScriptMethods $SDK @{
        Root = {
            git rev-parse --show-toplevel
        }
        Extend = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$ModuleName,
                [Parameter(Mandatory = $true)]
                $ModuleObject
            )

            $this | Add-Member -MemberType NoteProperty -Name $ModuleName -Value $ModuleObject -Force
        }
        Job = {
            param(
                [Parameter(Mandatory = $true)]
                [scriptblock]$ScriptBlock,
                [int] $Timeout,
                [System.Collections.IDictionary] $Env = @{}
            )
            $job = Start-Job -ScriptBlock {
                param(
                    [string] $InnerJob,
                    [System.Collections.IDictionary] $EnvVars,
                    [string] $SDKPath
                )

                foreach( $name in $EnvVars.Keys ){
                    Set-Variable -Name $name -Value $EnvVars[$name] -Scope Global
                }

                . $SDKPath

                $sb = [scriptblock]::Create($InnerJob)
                & $sb
            } -ArgumentList $ScriptBlock.ToString(), $Env, $this.Path

            # Return true if timed out, false otherwise
            if( $Timeout -gt 0 ){
                $completed = $job | Wait-Job -Timeout $Timeout
                if( -not $completed ){
                    Stop-Job $job | Out-Null
                    return $true
                }
                return $false
            } Else {
                $job | Wait-Job | Out-Null
                return $false
            }
        }
    }

    & "$PSScriptRoot/Settings.ps1" -SDK $SDK
    & "$PSScriptRoot/Network.ps1" -SDK $SDK
    & "$PSScriptRoot/General.ps1" -SDK $SDK
    & "$PSScriptRoot/Vbox.ps1" -SDK $SDK
    & "$PSScriptRoot/Multipass.ps1" -SDK $SDK

    Export-ModuleMember -Variable SDK
} -ArgumentList ([bool] $Globalize) | Import-Module -Force