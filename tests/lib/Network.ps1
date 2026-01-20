param(
    [Parameter(Mandatory = $true)]
    $SDK
)

New-Module -Name SDK.Network -ScriptBlock {
    param(
        [Parameter(Mandatory = $true)]
        $SDK
    )

    $mod = @{ SDK = $SDK }

    . "$PSScriptRoot\helpers\PowerShell.ps1"

    $Network = New-Object PSObject

    Add-ScriptMethods $Network @{
        GetGuestAdapter = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$AdapterName
            )

            $adapter = Get-NetAdapter -Name $AdapterName -ErrorAction SilentlyContinue
            if (-not $adapter) {
                Write-Warning "Network adapter '$AdapterName' not found."
            }

            $vswitch = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -match "^vEthernet\s*\(.*$([regex]::Escape($AdapterName)).*\)$"
            } | Select-Object -First 1

            if( ($null -eq $vswitch) -and ($null -eq $adapter) ) {
                Write-Warning "Virtual switch for adapter '$AdapterName' not found."
                return $null
            }

            if( $null -ne $vswitch ) {
                return $vswitch
            } Else {
                return $adapter
            }
        }
        TestSSH = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Address,
                [int]$Port = 22
            )

            $client = New-Object System.Net.Sockets.TcpClient
            try {
                $asyncResult = $client.BeginConnect($Address, $Port, $null, $null)
                $waitHandle = $asyncResult.AsyncWaitHandle.WaitOne(5000, $false)

                if( $waitHandle -and $client.Connected ) {
                    $client.Close()
                    return $true
                }
            } catch {
                # Skip to cleanup
            } finally {
                try {
                    $client.Close()
                } catch {
                    # Ignore
                }
            }

            return $false
        }
        UntilSSH = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Address,
                [int]$Port = 22,
                [int]$TimeoutSeconds
            )
            return $mod.SDK.Job({
                while(-not $SDK.Network.TestSSH($Address, $Port)) {
                    Start-Sleep -Seconds 5
                }
            }, $TimeoutSeconds, @{
                Address = $Address
                Port = $Port
            })
        }
        SSH = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Username,
                [Parameter(Mandatory = $true)]
                [string]$Address,
                [int]$Port = 22,
                [string]$Command = "",
                [string]$KeyPath = $mod.SDK.General.KeyPath
            )

            $key_path = If( Test-Path $KeyPath ) {
                "$(Resolve-Path $KeyPath)"
            } Else {
                "$(Resolve-Path "$env:USERPROFILE\.ssh\$KeyPath" -ErrorAction SilentlyContinue)"
            }

            if (-not (Test-Path $key_path)) {
                throw "SSH key not found at path: $key_path"
            }

            $params = @(
                "-o", "BatchMode=yes",
                "-o", "StrictHostKeyChecking=no",
                "-o", "UserKnownHostsFile=/dev/null",
                "-o", "ConnectTimeout=10",
                "-i", $key_path,
                "-p", $Port,
                "$Username@$Address"
            )

            Try {
                $output = & ssh @params $Command 2>&1
                return @{
                    Output = $output
                    ExitCode = $LASTEXITCODE
                    Success = ($LASTEXITCODE -eq 0)
                }
            } Catch {
                return @{
                    Output = $_.Exception.Message
                    ExitCode = 1
                    Success = $false
                }
            }
        }
    }

    $SDK.Extend("Network", $Network)
    
    # Export nothing. This module only modifies the SDK object.
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force