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
        "sendmail alias exists" = {
            param($Worker)
            $result = $Worker.Exec("test -L /usr/sbin/sendmail")
            $SDK.Testing.Record(@{
                Test = "6.7.3"; Name = "sendmail alias exists"
                Pass = $result.Success; Output = "/usr/sbin/sendmail"
            })
        }
        "SMTP host matches" = {
            param($Worker)
            if (-not $smtpConfigured) { $SDK.Testing.Verifications.Fork("6.7.4", "SKIP", "No SMTP configured"); return }
            $msmtprc = $Worker.Exec("sudo cat /etc/msmtprc").Output
            $SDK.Testing.Record(@{
                Test = "6.7.4"; Name = "SMTP host matches"
                Pass = ($msmtprc -match "host\s+$([regex]::Escape($smtp.host))"); Output = "Expected: $($smtp.host)"
            })
        }
        "SMTP port matches" = {
            param($Worker)
            if (-not $smtpConfigured) { $SDK.Testing.Verifications.Fork("6.7.4", "SKIP", "No SMTP configured"); return }
            $msmtprc = $Worker.Exec("sudo cat /etc/msmtprc").Output
            $SDK.Testing.Record(@{
                Test = "6.7.4"; Name = "SMTP port matches"
                Pass = ($msmtprc -match "port\s+$($smtp.port)"); Output = "Expected: $($smtp.port)"
            })
        }
        "SMTP from matches" = {
            param($Worker)
            if (-not $smtpConfigured) { $SDK.Testing.Verifications.Fork("6.7.4", "SKIP", "No SMTP configured"); return }
            $msmtprc = $Worker.Exec("sudo cat /etc/msmtprc").Output
            $SDK.Testing.Record(@{
                Test = "6.7.4"; Name = "SMTP from matches"
                Pass = ($msmtprc -match "from\s+$([regex]::Escape($smtp.from_email))"); Output = "Expected: $($smtp.from_email)"
            })
        }
        "SMTP user matches" = {
            param($Worker)
            if (-not $smtpConfigured) { $SDK.Testing.Verifications.Fork("6.7.4", "SKIP", "No SMTP configured"); return }
            $msmtprc = $Worker.Exec("sudo cat /etc/msmtprc").Output
            $SDK.Testing.Record(@{
                Test = "6.7.4"; Name = "SMTP user matches"
                Pass = ($msmtprc -match "user\s+$([regex]::Escape($smtp.user))"); Output = "Expected: $($smtp.user)"
            })
        }
        "Provider config valid" = {
            param($Worker)
            if (-not $smtpConfigured) { $SDK.Testing.Verifications.Fork("6.7.5", "SKIP", "No SMTP configured"); return }
            $msmtprc = $Worker.Exec("sudo cat /etc/msmtprc").Output
            $providerName = switch -Regex ($smtp.host) {
                'smtp\.sendgrid\.net' { 'SendGrid'; break }
                'email-smtp\..+\.amazonaws\.com' { 'AWS SES'; break }
                'smtp\.gmail\.com' { 'Gmail'; break }
                '^localhost$|^127\.' { 'Proton Bridge'; break }
                'smtp\.office365\.com' { 'M365'; break }
                default { 'Generic' }
            }
            $providerPass = switch ($providerName) {
                'SendGrid' { $msmtprc -match 'user\s+apikey' }
                'AWS SES' { $smtp.port -in @(587, 465) }
                'Gmail' { $msmtprc -match 'passwordeval' }
                'Proton Bridge' { $msmtprc -match 'tls_certcheck\s+off' }
                'M365' { $smtp.port -eq 587 }
                default { $true }
            }
            $SDK.Testing.Record(@{
                Test = "6.7.5"; Name = "Provider config valid ($providerName)"
                Pass = $providerPass; Output = "Provider: $providerName"
            })
        }
        "Auth method valid" = {
            param($Worker)
            if (-not $smtpConfigured) { $SDK.Testing.Verifications.Fork("6.7.6", "SKIP", "No SMTP configured"); return }
            $msmtprc = $Worker.Exec("sudo cat /etc/msmtprc").Output
            $authMethod = if ($msmtprc -match 'auth\s+(\S+)') { $matches[1] } else { 'on' }
            $validAuth = @('on', 'plain', 'login', 'xoauth2', 'oauthbearer', 'external')
            $authPass = $authMethod -in $validAuth
            if ($authMethod -in @('xoauth2', 'oauthbearer')) { $authPass = $authPass -and ($msmtprc -match 'passwordeval') }
            $SDK.Testing.Record(@{
                Test = "6.7.6"; Name = "Auth method valid"
                Pass = $authPass; Output = "auth=$authMethod"
            })
        }
        "TLS settings valid" = { param($Worker) }
        "Credential config valid" = { param($Worker) }
        "Root alias configured" = { param($Worker) }
        "msmtp-config helper exists" = { param($Worker) }
        "Test email sent" = { param($Worker) }
    })
} -ArgumentList $SDK
