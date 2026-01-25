function Add-CommonWorkerMethods {
    param($Worker, $SDK)

    Add-ScriptMethods $Worker @{
        Ensure = {
            if (-not $this.Exists()) {
                return $this.Create()
            }
            return $true
        }
    }
}
