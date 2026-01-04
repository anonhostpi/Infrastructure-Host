param(
    [string]$VMName = "test-autoinstall",
    [ValidateSet("Enter", "Yes", "No", "Text")]
    [string]$Action = "Enter",
    [string]$Text = ""
)

$vmMgmt = Get-WmiObject -Namespace "root\virtualization\v2" -Class Msvm_ComputerSystem |
    Where-Object { $_.ElementName -eq $VMName }

if (-not $vmMgmt) {
    Write-Host "VM '$VMName' not found" -ForegroundColor Red
    exit 1
}

$keyboard = Get-WmiObject -Namespace "root\virtualization\v2" -Class Msvm_Keyboard -Filter "SystemName='$($vmMgmt.Name)'"

if (-not $keyboard) {
    Write-Host "No keyboard controller found for VM" -ForegroundColor Red
    exit 1
}

switch ($Action) {
    "Enter" {
        Write-Host "Sending Enter key to $VMName..."
        $keyboard.TypeKey(0x0D) | Out-Null
    }
    "Yes" {
        Write-Host "Sending 'y' + Enter to $VMName..."
        $keyboard.TypeKey(0x59) | Out-Null
        Start-Sleep -Milliseconds 200
        $keyboard.TypeKey(0x0D) | Out-Null
    }
    "No" {
        Write-Host "Sending 'n' + Enter to $VMName..."
        $keyboard.TypeKey(0x4E) | Out-Null
        Start-Sleep -Milliseconds 200
        $keyboard.TypeKey(0x0D) | Out-Null
    }
    "Text" {
        if (-not $Text) {
            Write-Host "No text provided" -ForegroundColor Red
            exit 1
        }
        Write-Host "Sending text to $VMName: $Text"
        foreach ($char in $Text.ToCharArray()) {
            $keyboard.TypeText($char) | Out-Null
            Start-Sleep -Milliseconds 30
        }
        $keyboard.TypeKey(0x0D) | Out-Null
    }
}
Write-Host "Done"
