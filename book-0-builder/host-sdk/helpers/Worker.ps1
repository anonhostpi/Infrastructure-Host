function Add-CommonWorkerMethods {
    param($Worker, $SDK)

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
            # Implementation in next commit
        }
    }
}
