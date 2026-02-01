param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.MSMTPMail" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $smtp = $mod.SDK.Settings.SMTP
    $smtpConfigured = ($smtp -and $smtp.host)

    $mod.Tests = [ordered]@{
        "msmtp installed" = {
            param($Worker)
            $Worker.Test("6.7.1", "msmtp installed", "which msmtp", "msmtp")
        }
        "msmtp config exists" = {
            param($Worker)
            $Worker.Test("6.7.2", "msmtp config exists", "test -f /etc/msmtprc", { $true })
        }
        "sendmail alias exists" = {
            param($Worker)
            $Worker.Test("6.7.3", "sendmail alias exists", "test -L /usr/sbin/sendmail", { $true })
        }
        "SMTP host matches" = {
            param($Worker)
            if (-not $smtpConfigured) { $mod.SDK.Testing.Verifications.Fork("6.7.4", "SKIP", "No SMTP configured"); return }
            $Worker.Test("6.7.4", "SMTP host matches", "sudo cat /etc/msmtprc", "host\s+$([regex]::Escape($smtp.host))")
        }
        "SMTP port matches" = {
            param($Worker)
            if (-not $smtpConfigured) { $mod.SDK.Testing.Verifications.Fork("6.7.4", "SKIP", "No SMTP configured"); return }
            $Worker.Test("6.7.4", "SMTP port matches", "sudo cat /etc/msmtprc", "port\s+$($smtp.port)")
        }
        "SMTP from matches" = {
            param($Worker)
            if (-not $smtpConfigured) { $mod.SDK.Testing.Verifications.Fork("6.7.4", "SKIP", "No SMTP configured"); return }
            $msmtprc = $Worker.Exec("sudo cat /etc/msmtprc").Output
            $mod.SDK.Testing.Record(@{
                Test = "6.7.4"; Name = "SMTP from matches"
                Pass = ($msmtprc -match "from\s+$([regex]::Escape($smtp.from_email))"); Output = "Expected: $($smtp.from_email)"
            })
        }
        "SMTP user matches" = {
            param($Worker)
            if (-not $smtpConfigured) { $mod.SDK.Testing.Verifications.Fork("6.7.4", "SKIP", "No SMTP configured"); return }
            $msmtprc = $Worker.Exec("sudo cat /etc/msmtprc").Output
            $mod.SDK.Testing.Record(@{
                Test = "6.7.4"; Name = "SMTP user matches"
                Pass = ($msmtprc -match "user\s+$([regex]::Escape($smtp.user))"); Output = "Expected: $($smtp.user)"
            })
        }
        "Provider config valid" = {
            param($Worker)
            if (-not $smtpConfigured) { $mod.SDK.Testing.Verifications.Fork("6.7.5", "SKIP", "No SMTP configured"); return }
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
            $mod.SDK.Testing.Record(@{
                Test = "6.7.5"; Name = "Provider config valid ($providerName)"
                Pass = $providerPass; Output = "Provider: $providerName"
            })
        }
        "Auth method valid" = {
            param($Worker)
            if (-not $smtpConfigured) { $mod.SDK.Testing.Verifications.Fork("6.7.6", "SKIP", "No SMTP configured"); return }
            $msmtprc = $Worker.Exec("sudo cat /etc/msmtprc").Output
            $authMethod = if ($msmtprc -match 'auth\s+(\S+)') { $matches[1] } else { 'on' }
            $validAuth = @('on', 'plain', 'login', 'xoauth2', 'oauthbearer', 'external')
            $authPass = $authMethod -in $validAuth
            if ($authMethod -in @('xoauth2', 'oauthbearer')) { $authPass = $authPass -and ($msmtprc -match 'passwordeval') }
            $mod.SDK.Testing.Record(@{
                Test = "6.7.6"; Name = "Auth method valid"
                Pass = $authPass; Output = "auth=$authMethod"
            })
        }
        "TLS settings valid" = {
            param($Worker)
            if (-not $smtpConfigured) { $mod.SDK.Testing.Verifications.Fork("6.7.7", "SKIP", "No SMTP configured"); return }
            $msmtprc = $Worker.Exec("sudo cat /etc/msmtprc").Output
            $tlsOn = ($msmtprc -match 'tls\s+on')
            $implicitTls = ($smtp.port -eq 465 -and ($msmtprc -match 'tls_starttls\s+off'))
            $mod.SDK.Testing.Record(@{
                Test = "6.7.7"; Name = "TLS settings valid"
                Pass = ($tlsOn -or $implicitTls); Output = "tls=on, implicit=$implicitTls"
            })
        }
        "Credential config valid" = {
            param($Worker)
            if (-not $smtpConfigured) { $mod.SDK.Testing.Verifications.Fork("6.7.8", "SKIP", "No SMTP configured"); return }
            $msmtprc = $Worker.Exec("sudo cat /etc/msmtprc").Output
            $hasCreds = ($msmtprc -match 'password\s') -or ($msmtprc -match 'passwordeval')
            if (-not $hasCreds) { $hasCreds = $Worker.Exec("sudo test -f /etc/msmtp-password").Success }
            $mod.SDK.Testing.Record(@{
                Test = "6.7.8"; Name = "Credential config valid"
                Pass = $hasCreds; Output = if ($hasCreds) { "Credentials configured" } else { "No credentials found" }
            })
        }
        "Root alias configured" = {
            param($Worker)
            if (-not $smtpConfigured) { $mod.SDK.Testing.Verifications.Fork("6.7.9", "SKIP", "No SMTP configured"); return }
            $aliases = $Worker.Exec("cat /etc/aliases").Output
            $aliasPass = ($aliases -match "root:")
            if ($smtp.recipient) { $aliasPass = $aliasPass -and ($aliases -match [regex]::Escape($smtp.recipient)) }
            $mod.SDK.Testing.Record(@{
                Test = "6.7.9"; Name = "Root alias configured"
                Pass = $aliasPass; Output = "Root alias in /etc/aliases"
            })
        }
        "msmtp-config helper exists" = {
            param($Worker)
            if (-not $smtpConfigured) { $mod.SDK.Testing.Verifications.Fork("6.7.10", "SKIP", "No SMTP configured"); return }
            $result = $Worker.Exec("test -x /usr/local/bin/msmtp-config")
            $mod.SDK.Testing.Record(@{
                Test = "6.7.10"; Name = "msmtp-config helper exists"
                Pass = $result.Success; Output = "/usr/local/bin/msmtp-config"
            })
        }
        "Test email sent" = {
            param($Worker)
            if (-not $smtpConfigured) { $mod.SDK.Testing.Verifications.Fork("6.7.11", "SKIP", "No SMTP configured"); return }
            $msmtprc = $Worker.Exec("sudo cat /etc/msmtprc").Output
            $hasInline = ($msmtprc -match 'password\s+\S' -and $msmtprc -notmatch 'passwordeval')
            if (-not $hasInline -or -not $smtp.recipient) {
                $mod.SDK.Testing.Verifications.Fork("6.7.11", "SKIP", "No inline password or recipient"); return
            }
            $subject = "Infrastructure-Host Verification Test"
            $result = $Worker.Exec("echo -e 'Subject: $subject\n\nAutomated test.' | sudo msmtp '$($smtp.recipient)'")
            $logCheck = $Worker.Exec("sudo tail -1 /var/log/msmtp.log")
            $mod.SDK.Testing.Record(@{
                Test = "6.7.11"; Name = "Test email sent"
                Pass = ($result.Success -and $logCheck.Output -match $smtp.recipient)
                Output = if ($result.Success) { "Email sent" } else { $result.Output }
            })
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
