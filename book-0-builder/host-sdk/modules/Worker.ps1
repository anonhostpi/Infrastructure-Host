param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Worker -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }

    function Add-CommonWorkerMethods {
        param($Worker)

        Add-ScriptMethods $Worker @{
        Ensure = {
            if (-not $this.Exists()) {
                return $this.Create()
            }
            return $true
        }
        Test = {
            param(
                [string]$TestId,
                [string]$Name,
                [string]$Command,
                [string]$ExpectedPattern
            )

            $mod.SDK.Log.Debug("Running test: $Name")
            try {
                $result = $this.Exec($Command)
                $pass = $result.Success -and ($result.Output -join "`n") -match $ExpectedPattern
                $testResult = @{ Test = $TestId; Name = $Name; Pass = $pass; Output = $result.Output; Error = $result.Error }
                $mod.SDK.Testing.Record($testResult)
                if ($pass) { $mod.SDK.Log.Write("[PASS] $Name", "Green") }
                else { $mod.SDK.Log.Write("[FAIL] $Name", "Red"); if ($result.Error) { $mod.SDK.Log.Error("  Error: $($result.Error)") } }
                return $testResult
            }
            catch {
                $mod.SDK.Log.Write("[FAIL] $Name - Exception: $_", "Red")
                $testResult = @{ Test = $TestId; Name = $Name; Pass = $false; Error = $_.ToString() }
                $mod.SDK.Testing.Record($testResult)
                return $testResult
            }
        }
    }

    $Worker = New-Object PSObject
    $SDK.Extend("Worker", $Worker)

    Export-ModuleMember -Function Add-CommonWorkerMethods
} -ArgumentList $SDK | Import-Module -Force
