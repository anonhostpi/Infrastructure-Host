param(
    [Parameter(Mandatory = $true)]
    $SDK
)

New-Module -Name SDK.Multipass -ScriptBlock {
    param(
        [Parameter(Mandatory = $true)]
        $SDK
    )

    $mod = @{ SDK = $SDK }

    . "$PSScriptRoot\helpers\PowerShell.ps1"

    $Multipass = New-Object PSObject

    #region: Main utility method
    Add-ScriptMethods $Multipass @{
        Invoke = {

            $output = & multipass @args 2>&1
            return @{
                Output = $output
                ExitCode = $LASTEXITCODE
            }
        }
    }

    #region: VM info methods
    Add-ScriptMethods $Multipass @{
        Info = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName,
                [string]$Format = "json"
            )
            $result = $this.Invoke("info", $VMName, "--format", $Format)
            if ($Format -eq "json" -and $result.ExitCode -eq 0) {
                return $result.Output | ConvertFrom-Json
            }
            return $result
        }
        Address = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            $info = $this.Info($VMName, "json")
            if ($info -and $info.$VMName -and $info.$VMName.ipv4) {
                return $info.$VMName.ipv4 | Select-Object -First 1
            }
            return $null
        }
        List = {
            $result = $this.Invoke("list", "--format", "csv")

            if ($result.ExitCode -ne 0) {
                return @()
            }
            return $result.Output | ConvertFrom-Csv
        }
        Status = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            $result = $this.Exec($VMName, "cloud-init status")
            return $result.Output
        }
    }

    #region: VM lifecycle methods
    Add-ScriptMethods $Multipass @{
        Exists = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            $list = $this.List()
            return ($list | Where-Object { $_.Name -eq $VMName }).Count -gt 0
        }
        Running = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            if (-not $this.Exists($VMName)) {
                return $false
            }
            $list = $this.List()
            $vm = $list | Where-Object { $_.Name -eq $VMName }
            return "Running" -eq $vm.State
        }
        Start = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            return $this.Invoke("start", $VMName).ExitCode -eq 0
        }
        UntilInstalled = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName,
                [int]$TimeoutSeconds = 600
            )
            $result = $this.Exec($VMName, "cloud-init status --wait")
            return $result.ExitCode -eq 0
        }
        Shutdown = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName,
                [bool]$Force = $false
            )
            if ($Force) {
                return $this.Invoke("stop", "--force", $VMName).ExitCode -eq 0
            } else {
                return $this.Invoke("stop", $VMName).ExitCode -eq 0
            }
        }
        UntilShutdown = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName,
                [int]$TimeoutSeconds = 60
            )
            if (-not $this.Running($VMName)) {
                return $false
            }
            # Returns true if timeout reached
            return $mod.SDK.Job({
                while ($SDK.Multipass.Running($VMName)) {
                    Start-Sleep -Seconds 1
                }
            }, $TimeoutSeconds, @{
                VMName = $VMName
            })
        }
    }

    #region: VM creation and destruction
    Add-ScriptMethods $Multipass @{
        Create = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName,
                [string]$CloudInitPath,
                [string]$Network,
                [int]$CPUs = 2,
                [string]$Memory = "4G",
                [string]$Disk = "40G",
                [string]$Image = ""  # Empty uses default Ubuntu LTS
            )

            $launchArgs = @("launch", "--name", $VMName, "--cpus", $CPUs, "--memory", $Memory, "--disk", $Disk)

            if (-not [string]::IsNullOrWhiteSpace($Network)) {
                $launchArgs += @("--network", $Network)
            }

            if (-not [string]::IsNullOrWhiteSpace($CloudInitPath) -and (Test-Path $CloudInitPath)) {
                $launchArgs += @("--cloud-init", $CloudInitPath)
            }

            if (-not [string]::IsNullOrWhiteSpace($Image)) {
                $launchArgs += $Image
            }

            $result = $this.Invoke($launchArgs)
            return $result.ExitCode -eq 0
        }
        Destroy = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            if ($this.Exists($VMName)) {
                $this.Invoke("delete", "--purge", $VMName) | Out-Null
            }
        }
        Purge = {
            return $this.Invoke("purge").ExitCode -eq 0
        }
    }

    #region: VM configuration methods
    Add-ScriptMethods $Multipass @{
        Mount = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName,
                [Parameter(Mandatory = $true)]
                [string]$HostPath,
                [Parameter(Mandatory = $true)]
                [string]$GuestPath
            )
            return $this.Invoke("mount", $HostPath, "${VMName}:${GuestPath}").ExitCode -eq 0
        }
        Unmount = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName,
                [string]$GuestPath
            )
            if ([string]::IsNullOrWhiteSpace($GuestPath)) {
                return $this.Invoke("unmount", $VMName).ExitCode -eq 0
            } else {
                return $this.Invoke("unmount", "${VMName}:${GuestPath}").ExitCode -eq 0
            }
        }
        Transfer = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Source,
                [Parameter(Mandatory = $true)]
                [string]$Destination
            )
            return $this.Invoke("transfer", $Source, $Destination).ExitCode -eq 0
        }
    }

    #region: Command execution
    Add-ScriptMethods $Multipass @{
        Exec = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName,
                [Parameter(Mandatory = $true)]
                [string]$Command,
                [string]$WorkingDir
            )
            $execArgs = @("exec", $VMName)
            if (-not [string]::IsNullOrWhiteSpace($WorkingDir)) {
                $execArgs += @("--working-directory", $WorkingDir)
            }
            $execArgs += @("--", "bash", "-c", $Command)
            return $this.Invoke($execArgs)
        }
        Shell = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            # This starts an interactive shell - mainly for manual use
            & multipass shell $VMName
        }
    }

    $SDK.Extend("Multipass", $Multipass)

    # Export nothing. This module only modifies the SDK object.
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
