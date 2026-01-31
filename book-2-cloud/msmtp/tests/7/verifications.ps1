param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.MSMTPMail" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $smtp = $SDK.Settings.SMTP
    $smtpConfigured = ($smtp -and $smtp.host)

    $SDK.Testing.Verifications.Register("msmtp", 7, [ordered]@{
        "msmtp installed" = {
            param($Worker)
            $result = $Worker.Exec("which msmtp")
            $SDK.Testing.Record(@{
                Test = "6.7.1"; Name = "msmtp installed"
                Pass = ($result.Success -and $result.Output -match "msmtp"); Output = $result.Output
            })
        }
        "msmtp config exists" = {
            param($Worker)
            $result = $Worker.Exec("test -f /etc/msmtprc")
            $SDK.Testing.Record(@{
                Test = "6.7.2"; Name = "msmtp config exists"
                Pass = $result.Success; Output = "/etc/msmtprc"
            })
        }
        "sendmail alias exists" = { param($Worker) }
        "SMTP host matches" = { param($Worker) }
        "SMTP port matches" = { param($Worker) }
        "SMTP from matches" = { param($Worker) }
        "SMTP user matches" = { param($Worker) }
        "Provider config valid" = { param($Worker) }
        "Auth method valid" = { param($Worker) }
        "TLS settings valid" = { param($Worker) }
        "Credential config valid" = { param($Worker) }
        "Root alias configured" = { param($Worker) }
        "msmtp-config helper exists" = { param($Worker) }
        "Test email sent" = { param($Worker) }
    })
} -ArgumentList $SDK
