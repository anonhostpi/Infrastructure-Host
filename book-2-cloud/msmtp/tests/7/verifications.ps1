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
            $Worker.Test("6.7.4", "SMTP from matches", "sudo cat /etc/msmtprc", "from\s+$([regex]::Escape($smtp.from_email))")
        }
        "SMTP user matches" = {
            param($Worker)
            if (-not $smtpConfigured) { $mod.SDK.Testing.Verifications.Fork("6.7.4", "SKIP", "No SMTP configured"); return }
            $Worker.Test("6.7.4", "SMTP user matches", "sudo cat /etc/msmtprc", "user\s+$([regex]::Escape($smtp.user))")
        }
        "Provider config valid" = {
            param($Worker)
            if (-not $smtpConfigured) { $mod.SDK.Testing.Verifications.Fork("6.7.5", "SKIP", "No SMTP configured"); return }
            $Worker.Test("6.7.5", "Provider config valid", "sudo cat /etc/msmtprc", { param($out)
            $providerName = switch -Regex ($smtp.host) {
                'smtp\.sendgrid\.net' { 'SendGrid'; break }
                'email-smtp\..+\.amazonaws\.com' { 'AWS SES'; break }
                'smtp\.gmail\.com' { 'Gmail'; break }
                '^localhost$|^127\.' { 'Proton Bridge'; break }
                'smtp\.office365\.com' { 'M365'; break }
                default { 'Generic' }
            }
            switch ($providerName) {
                'SendGrid' { $out -match 'user\s+apikey' }
                'AWS SES' { $smtp.port -in @(587, 465) }
                'Gmail' { $out -match 'passwordeval' }
                'Proton Bridge' { $out -match 'tls_certcheck\s+off' }
                'M365' { $smtp.port -eq 587 }
                default { $true }
            }
            })
        }
        "Auth method valid" = {
            param($Worker)
            if (-not $smtpConfigured) { $mod.SDK.Testing.Verifications.Fork("6.7.6", "SKIP", "No SMTP configured"); return }
            $Worker.Test("6.7.6", "Auth method valid", "sudo cat /etc/msmtprc", { param($out)
            $authMethod = if ($out -match 'auth\s+(\S+)') { $matches[1] } else { 'on' }
            $validAuth = @('on', 'plain', 'login', 'xoauth2', 'oauthbearer', 'external')
            $authPass = $authMethod -in $validAuth
            if ($authMethod -in @('xoauth2', 'oauthbearer')) { $authPass = $authPass -and ($out -match 'passwordeval') }
            $authPass
            })
        }
        "TLS settings valid" = {
            param($Worker)
            if (-not $smtpConfigured) { $mod.SDK.Testing.Verifications.Fork("6.7.7", "SKIP", "No SMTP configured"); return }
            $Worker.Test("6.7.7", "TLS settings valid", "sudo cat /etc/msmtprc", { param($out)
            ($out -match 'tls\s+on') -or ($smtp.port -eq 465 -and ($out -match 'tls_starttls\s+off'))
            })
        }
        "Credential config valid" = {
            param($Worker)
            if (-not $smtpConfigured) { $mod.SDK.Testing.Verifications.Fork("6.7.8", "SKIP", "No SMTP configured"); return }
            $Worker.Test("6.7.8", "Credential config valid", "sudo cat /etc/msmtprc", { param($out)
            $hasCreds = ($out -match 'password\s') -or ($out -match 'passwordeval')
            if (-not $hasCreds) { $hasCreds = $Worker.Exec("sudo test -f /etc/msmtp-password").Success }
            $hasCreds
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
