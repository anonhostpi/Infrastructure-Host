param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Testing.Verifications -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Verifications = New-Object PSObject

    # Methods added in following commits

    $SDK.Testing | Add-Member -MemberType NoteProperty -Name Verifications -Value $Verifications
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
