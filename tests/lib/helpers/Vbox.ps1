New-Module -Name Helpers.Vbox -ScriptBlock {
    function Get-VBoxManagePath {
        if ($script:VBoxManage) { return $script:VBoxManage }
        if ($global:VBoxManage) { return $global:VBoxManage }
        return "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
    }

    function Invoke-VBoxManage {
        param(
            [Parameter(Mandatory = $true)]
            [string[]]$Arguments
        )

        $vboxmanage = Get-VBoxManagePath
        if (-not (Test-Path $vboxmanage)) {
            throw "VBoxManage not found at: $vboxmanage"
        }

        # VBoxManage outputs progress (0%...10%...) to stderr which triggers
        # PowerShell errors when ErrorActionPreference is set to Stop
        # Temporarily set to Continue to prevent this
        $savedEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'

        try {
            $result = & $vboxmanage @Arguments 2>&1
            $exitCode = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $savedEAP
        }

        # Filter out progress lines from output
        $filteredResult = $result | Where-Object {
            $_ -notmatch '^\d+%\.{3}'
        }

        return @{
            Output = $filteredResult
            ExitCode = $exitCode
        }
    }

    Export-ModuleMember -Function Get-VBoxManagePath, Invoke-VBoxManage
} | Import-Module -Force