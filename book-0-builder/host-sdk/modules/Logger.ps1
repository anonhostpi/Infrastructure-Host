param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Logger -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Logger = New-Object PSObject -Property @{ Level = "Info"; Path = $null }

    Add-ScriptMethods $Logger @{
        Write = {
            param([string]$Message, [string]$ForegroundColor = "White", [string]$BackgroundColor = $null)
            $params = @{ Object = $Message; ForegroundColor = $ForegroundColor }
            if ($BackgroundColor) { $params.BackgroundColor = $BackgroundColor }
            Write-Host @params
        }
        Debug = { param([string]$Message) if ($this.Level -eq "Debug") { $this.Write("[DEBUG] $Message", "Gray") } }
        Info  = { param([string]$Message) $this.Write("[INFO] $Message", "Cyan") }
        Warn  = { param([string]$Message) $this.Write("[WARN] $Message", "Yellow") }
        Error = { param([string]$Message) $this.Write("[ERROR] $Message", "Red") }
        Step  = { param([string]$Message, [int]$Current, [int]$Total) $this.Write("[$Current/$Total] $Message", "Cyan") }
        Start = {
            param([string]$Path)
            $this.Path = $Path
            Start-Transcript -Path $Path -Append
            $this.Info("Transcript started: $Path")
        }
        Stop = {
            if ($this.Path) {
                Stop-Transcript
                $this.Info("Transcript stopped: $($this.Path)")
                $this.Path = $null
            }
        }
    }

    $SDK.Extend("Log", $Logger)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
