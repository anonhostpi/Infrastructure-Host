param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Testing -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Testing = New-Object PSObject -Property @{ Results = @(); PassCount = 0; FailCount = 0 }

    # Properties and methods added in following commits

    $SDK.Extend("Testing", $Testing)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
