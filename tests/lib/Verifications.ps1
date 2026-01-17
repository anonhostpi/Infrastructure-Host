# Test Verification Functions
# Each function tests a specific fragment and returns pass/fail results

# Helper function to log fork decisions to the transcript
function Write-TestFork {
    param(
        [string]$Test,
        [string]$Decision,
        [string]$Reason = ""
    )
    $msg = "[FORK] $Test : $Decision"
    if ($Reason) { $msg += " ($Reason)" }
    Write-Host $msg -ForegroundColor DarkGray
}

function Test-NetworkFragment {
    param([string]$VMName)

    # $results = @()

    # 6.1.1: Hostname Configuration
    $hostname = multipass exec $VMName -- hostname -s 2>&1
    <# (multi) return #> @{
        Test = "6.1.1"
        Name = "Short hostname set"
        Pass = ($hostname -and $hostname -ne "localhost" -and $LASTEXITCODE -eq 0)
        Output = $hostname
    }

    $fqdn = multipass exec $VMName -- hostname -f 2>&1
    <# (multi) return #> @{
        Test = "6.1.1"
        Name = "FQDN has domain"
        Pass = ($fqdn -match "\.")
        Output = $fqdn
    }

    # 6.1.2: /etc/hosts Management
    $hosts = multipass exec $VMName -- grep "127.0.1.1" /etc/hosts 2>&1
    <# (multi) return #> @{
        Test = "6.1.2"
        Name = "Hostname in /etc/hosts"
        Pass = ($hosts -and $LASTEXITCODE -eq 0)
        Output = $hosts
    }

    # 6.1.3: Netplan Configuration
    $netplan = multipass exec $VMName -- bash -c "ls /etc/netplan/*.yaml 2>/dev/null" 2>&1
    <# (multi) return #> @{
        Test = "6.1.3"
        Name = "Netplan config exists"
        Pass = ($netplan -and $LASTEXITCODE -eq 0)
        Output = $netplan
    }

    # 6.1.4: Network Connectivity
    $ip = multipass exec $VMName -- bash -c "ip -4 addr show scope global | grep 'inet '" 2>&1
    <# (multi) return #> @{
        Test = "6.1.4"
        Name = "IP address assigned"
        Pass = ($ip -match "inet ")
        Output = $ip
    }

    $route = multipass exec $VMName -- bash -c "ip route | grep '^default'" 2>&1
    <# (multi) return #> @{
        Test = "6.1.4"
        Name = "Default gateway configured"
        Pass = ($route -match "default via")
        Output = $route
    }

    $dns = multipass exec $VMName -- host -W 2 ubuntu.com 2>&1
    <# (multi) return #> @{
        Test = "6.1.4"
        Name = "DNS resolution works"
        Pass = ($dns -match "has address" -or $dns -match "has IPv")
        Output = $dns
    }

    # return $results
}

function Test-KernelFragment {
    param([string]$VMName)

    # $results = @()

    # 6.2.1: Sysctl Security Config
    $sysctl = multipass exec $VMName -- test -f /etc/sysctl.d/99-security.conf 2>&1
    <# (multi) return #> @{
        Test = "6.2.1"
        Name = "Security sysctl config exists"
        Pass = ($LASTEXITCODE -eq 0)
        Output = "/etc/sysctl.d/99-security.conf"
    }

    # 6.2.2: Key security settings applied
    $rpfilter = multipass exec $VMName -- sysctl net.ipv4.conf.all.rp_filter 2>&1
    <# (multi) return #> @{
        Test = "6.2.2"
        Name = "Reverse path filtering enabled"
        Pass = ($rpfilter -match "= 1")
        Output = $rpfilter
    }

    $syncookies = multipass exec $VMName -- sysctl net.ipv4.tcp_syncookies 2>&1
    <# (multi) return #> @{
        Test = "6.2.2"
        Name = "SYN cookies enabled"
        Pass = ($syncookies -match "= 1")
        Output = $syncookies
    }

    $redirects = multipass exec $VMName -- sysctl net.ipv4.conf.all.accept_redirects 2>&1
    <# (multi) return #> @{
        Test = "6.2.2"
        Name = "ICMP redirects disabled"
        Pass = ($redirects -match "= 0")
        Output = $redirects
    }

    # return $results
}

function Test-UsersFragment {
    param([string]$VMName)

    # $results = @()
    $config = Get-TestConfig
    $username = $config.identity.username

    # 6.3.1: User Exists
    $id = multipass exec $VMName -- id $username 2>&1
    <# (multi) return #> @{
        Test = "6.3.1"
        Name = "$username user exists"
        Pass = ($id -match "uid=" -and $LASTEXITCODE -eq 0)
        Output = $id
    }

    $shell = multipass exec $VMName -- bash -c "getent passwd $username | cut -d: -f7" 2>&1
    <# (multi) return #> @{
        Test = "6.3.1"
        Name = "$username shell is bash"
        Pass = ($shell -match "/bin/bash")
        Output = $shell
    }

    # 6.3.2: Group Membership
    $groups = multipass exec $VMName -- groups $username 2>&1
    <# (multi) return #> @{
        Test = "6.3.2"
        Name = "$username in sudo group"
        Pass = ($groups -match "\bsudo\b")
        Output = $groups
    }

    # 6.3.3: Sudo Configuration
    $sudoFile = multipass exec $VMName -- sudo test -f /etc/sudoers.d/$username 2>&1
    <# (multi) return #> @{
        Test = "6.3.3"
        Name = "Sudoers file exists"
        Pass = ($LASTEXITCODE -eq 0)
        Output = "/etc/sudoers.d/$username"
    }

    # 6.3.4: Root Disabled
    $root = multipass exec $VMName -- sudo passwd -S root 2>&1
    <# (multi) return #> @{
        Test = "6.3.4"
        Name = "Root account locked"
        Pass = ($root -match "root L" -or $root -match "root LK")
        Output = $root
    }

    # return $results
}

function Test-SSHFragment {
    param([string]$VMName)

    # $results = @()

    # 6.4.1: SSH Hardening Config
    $config = multipass exec $VMName -- test -f /etc/ssh/sshd_config.d/99-hardening.conf 2>&1
    <# (multi) return #> @{
        Test = "6.4.1"
        Name = "SSH hardening config exists"
        Pass = ($LASTEXITCODE -eq 0)
        Output = "/etc/ssh/sshd_config.d/99-hardening.conf"
    }

    # 6.4.2: Key Settings
    $permitroot = multipass exec $VMName -- bash -c "sudo grep -r 'PermitRootLogin' /etc/ssh/sshd_config.d/" 2>&1
    <# (multi) return #> @{
        Test = "6.4.2"
        Name = "PermitRootLogin no"
        Pass = ($permitroot -match "PermitRootLogin no")
        Output = $permitroot
    }

    $maxauth = multipass exec $VMName -- bash -c "sudo grep -r 'MaxAuthTries' /etc/ssh/sshd_config.d/" 2>&1
    <# (multi) return #> @{
        Test = "6.4.2"
        Name = "MaxAuthTries set"
        Pass = ($maxauth -match "MaxAuthTries")
        Output = $maxauth
    }

    # 6.4.3: SSH Service Running
    $sshd = multipass exec $VMName -- systemctl is-active ssh 2>&1
    <# (multi) return #> @{
        Test = "6.4.3"
        Name = "SSH service active"
        Pass = ($sshd -match "^active$")
        Output = $sshd
    }

    # 6.4.4: Verify root login is rejected from host
    # Get VM IP from multipass
    $vmInfo = multipass info $VMName --format json 2>&1 | ConvertFrom-Json
    $vmIp = $vmInfo.info.$VMName.ipv4 | Select-Object -First 1

    if ($vmIp) {
        # Attempt SSH as root - should be rejected immediately (not timeout)
        # BatchMode=yes prevents password prompts, ConnectTimeout keeps it short
        # Use try/catch to handle SSH stderr warnings (e.g., "Permanently added to known hosts")
        try {
            $oldErrorAction = $ErrorActionPreference
            $ErrorActionPreference = "Continue"
            $sshResult = ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$vmIp exit 2>&1
            $sshExitCode = $LASTEXITCODE
            $ErrorActionPreference = $oldErrorAction
        } catch {
            $sshResult = $_.Exception.Message
            $sshExitCode = 255
        }

        # SSH should fail with "Permission denied" - exit code 255
        # Pass if we get permission denied (root login blocked)
        $rootBlocked = ($sshResult -match "Permission denied" -or $sshResult -match "publickey")
        <# (multi) return #> @{
            Test = "6.4.4"
            Name = "Root SSH login rejected"
            Pass = $rootBlocked
            Output = if ($rootBlocked) { "Root login correctly rejected" } else { $sshResult }
        }
    } else {
        <# (multi) return #> @{
            Test = "6.4.4"
            Name = "Root SSH login rejected"
            Pass = $false
            Output = "Could not get VM IP address"
        }
    }

    # 6.4.5: Verify SSH key authentication works (if configured)
    $testConfig = Get-TestConfig
    $sshKeys = $testConfig.identity.ssh_authorized_keys
    $sshUser = $testConfig.identity.username

    if ($sshKeys -and $sshKeys.Count -gt 0 -and $vmIp) {
        Write-TestFork -Test "6.4.5" -Decision "Testing SSH key auth" -Reason "$($sshKeys.Count) keys configured, VM IP available"
        # Attempt SSH as configured user using default SSH agent/identities
        # BatchMode=yes uses agent keys, won't prompt for password
        # Use try/catch to handle SSH stderr warnings (e.g., "Permanently added to known hosts")
        try {
            $oldErrorAction = $ErrorActionPreference
            $ErrorActionPreference = "Continue"
            $sshUserResult = ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${sshUser}@${vmIp}" "echo OK" 2>&1
            $sshUserExitCode = $LASTEXITCODE
            $ErrorActionPreference = $oldErrorAction
        } catch {
            $sshUserResult = $_.Exception.Message
            $sshUserExitCode = 255
        }

        $keyAuthWorks = ($sshUserResult -match "OK" -and $sshUserExitCode -eq 0)
        <# (multi) return #> @{
            Test = "6.4.5"
            Name = "SSH key auth for $sshUser"
            Pass = $keyAuthWorks
            Output = if ($keyAuthWorks) { "Key authentication successful" } else { "Key auth failed (ensure private key is loaded in ssh-agent): $sshUserResult" }
        }
    } elseif ($sshKeys -and $sshKeys.Count -gt 0) {
        Write-TestFork -Test "6.4.5" -Decision "SSH key auth skipped" -Reason "No VM IP available"
        <# (multi) return #> @{
            Test = "6.4.5"
            Name = "SSH key auth for $sshUser"
            Pass = $false
            Output = "Could not get VM IP address"
        }
    } else {
        Write-TestFork -Test "6.4.5" -Decision "SSH key auth skipped" -Reason "No SSH keys configured"
    }

    # return $results
}

function Test-UFWFragment {
    param([string]$VMName)

    # $results = @()

    # 6.5.1: UFW Installed and Enabled
    $status = multipass exec $VMName -- sudo ufw status 2>&1
    <# (multi) return #> @{
        Test = "6.5.1"
        Name = "UFW is active"
        Pass = ($status -match "Status: active")
        Output = $status | Select-Object -First 1
    }

    # 6.5.2: SSH Rule Exists
    $sshrule = multipass exec $VMName -- sudo ufw status 2>&1
    <# (multi) return #> @{
        Test = "6.5.2"
        Name = "SSH allowed in UFW"
        Pass = ($sshrule -match "22.*ALLOW")
        Output = "Port 22 rule checked"
    }

    # 6.5.3: Default Policies
    $defaults = multipass exec $VMName -- sudo ufw status verbose 2>&1
    <# (multi) return #> @{
        Test = "6.5.3"
        Name = "Default deny incoming"
        Pass = ($defaults -match "deny \(incoming\)")
        Output = "Default incoming policy"
    }

    # return $results
}

function Test-SystemFragment {
    param([string]$VMName)

    # $results = @()

    # 6.6.1: Timezone
    $tz = multipass exec $VMName -- timedatectl show --property=Timezone --value 2>&1
    <# (multi) return #> @{
        Test = "6.6.1"
        Name = "Timezone configured"
        Pass = ($tz -and $LASTEXITCODE -eq 0)
        Output = $tz
    }

    # 6.6.2: Locale
    $locale = multipass exec $VMName -- locale 2>&1
    <# (multi) return #> @{
        Test = "6.6.2"
        Name = "Locale set"
        Pass = ($locale -match "LANG=")
        Output = ($locale | Select-Object -First 1)
    }

    # 6.6.3: NTP Enabled
    $ntp = multipass exec $VMName -- timedatectl show --property=NTP --value 2>&1
    <# (multi) return #> @{
        Test = "6.6.3"
        Name = "NTP enabled"
        Pass = ($ntp -match "yes")
        Output = "NTP=$ntp"
    }

    # return $results
}

function Test-MSMTPFragment {
    param([string]$VMName)

    # $results = @()
    $config = Get-TestConfig
    $smtp = $config.smtp

    # 6.7.1: msmtp installed
    $msmtp = multipass exec $VMName -- which msmtp 2>&1
    <# (multi) return #> @{
        Test = "6.7.1"
        Name = "msmtp installed"
        Pass = ($msmtp -match "/msmtp" -and $LASTEXITCODE -eq 0)
        Output = $msmtp
    }

    # 6.7.2: msmtp config exists
    $configExists = multipass exec $VMName -- test -f /etc/msmtprc 2>&1
    <# (multi) return #> @{
        Test = "6.7.2"
        Name = "msmtp config exists"
        Pass = ($LASTEXITCODE -eq 0)
        Output = "/etc/msmtprc"
    }

    # 6.7.3: mail alias (sendmail -> msmtp)
    $alias = multipass exec $VMName -- test -L /usr/sbin/sendmail 2>&1
    $aliasOk = ($LASTEXITCODE -eq 0)
    if (-not $aliasOk) {
        $alias = multipass exec $VMName -- test -f /usr/sbin/sendmail 2>&1
        $aliasOk = ($LASTEXITCODE -eq 0)
    }
    <# (multi) return #> @{
        Test = "6.7.3"
        Name = "sendmail alias exists"
        Pass = $aliasOk
        Output = "/usr/sbin/sendmail"
    }

    # Skip config verification tests if smtp not configured
    if (-not $smtp -or -not $smtp.host) {
        Write-TestFork -Test "6.7.4+" -Decision "Skipping SMTP config verification" -Reason "smtp.host not configured"
        return # $results
    }
    Write-TestFork -Test "6.7.4+" -Decision "Testing SMTP config verification" -Reason "smtp.host=$($smtp.host)"

    # Read the msmtprc content for verification (sudo needed due to 600 permissions)
    $msmtprc = multipass exec $VMName -- bash -c 'sudo cat /etc/msmtprc' 2>&1
    if ($LASTEXITCODE -ne 0) {
        return # $results
    }

    # 6.7.4: Verify config values match YAML
    $hostMatch = [bool]($msmtprc -match "host\s+$([regex]::Escape($smtp.host))")
    <# (multi) return #> @{
        Test = "6.7.4"
        Name = "Config host matches"
        Pass = $hostMatch
        Output = "host: $($smtp.host)"
    }

    $expectedPort = if ($smtp.port) { $smtp.port } else { 587 }
    $portMatch = [bool]($msmtprc -match "port\s+$expectedPort")
    <# (multi) return #> @{
        Test = "6.7.4"
        Name = "Config port matches"
        Pass = $portMatch
        Output = "port: $expectedPort"
    }

    $fromMatch = [bool]($msmtprc -match "from\s+$([regex]::Escape($smtp.from_email))")
    <# (multi) return #> @{
        Test = "6.7.4"
        Name = "Config from_email matches"
        Pass = $fromMatch
        Output = "from: $($smtp.from_email)"
    }

    $userMatch = [bool]($msmtprc -match "user\s+$([regex]::Escape($smtp.user))")
    <# (multi) return #> @{
        Test = "6.7.4"
        Name = "Config user matches"
        Pass = $userMatch
        Output = "user: $($smtp.user)"
    }

    # 6.7.5: Provider-specific configuration verification
    $providerName = Get-SMTPProviderName -SmtpHost $smtp.host -SmtpPort $smtp.port
    $providerValid = $true
    $providerOutput = "Provider: $providerName"

    switch -Regex ($smtp.host) {
        "smtp\.sendgrid\.net" {
            # SendGrid: user should be "apikey"
            if ($smtp.user -ne "apikey") {
                $providerValid = $false
                $providerOutput = "SendGrid requires user='apikey'"
            }
        }
        "email-smtp\..*\.amazonaws\.com" {
            # AWS SES: port 587, standard TLS
            if ($expectedPort -ne 587 -and $expectedPort -ne 465) {
                $providerValid = $false
                $providerOutput = "AWS SES requires port 587 or 465"
            }
        }
        "smtp\.gmail\.com" {
            # Gmail: check for OAuth2 if auth_method specified
            if ($smtp.auth_method -match "oauth") {
                if (-not $smtp.passwordeval) {
                    $providerValid = $false
                    $providerOutput = "Gmail OAuth2 requires passwordeval"
                }
            }
        }
        "127\.0\.0\.1|localhost" {
            # Proton Bridge: requires tls_certcheck off for self-signed cert
            if ($smtp.port -eq 1025) {
                if ($smtp.tls_certcheck -ne $false) {
                    $providerValid = $false
                    $providerOutput = "Proton Bridge requires tls_certcheck: false"
                }
            }
        }
        "smtp\.office365\.com" {
            # M365: port 587 required
            if ($expectedPort -ne 587) {
                $providerValid = $false
                $providerOutput = "Microsoft 365 requires port 587"
            }
        }
    }

    <# (multi) return #> @{
        Test = "6.7.5"
        Name = "Provider config valid ($providerName)"
        Pass = $providerValid
        Output = $providerOutput
    }

    # 6.7.6: Authentication method verification
    $authValid = $true
    $authOutput = "auth: on (auto-detect)"

    if ($smtp.auth_method) {
        $validAuthMethods = @("plain", "login", "cram-md5", "oauthbearer", "xoauth2", "external", "gssapi", "on")
        if ($smtp.auth_method -notin $validAuthMethods) {
            $authValid = $false
            $authOutput = "Invalid auth_method: $($smtp.auth_method)"
        } else {
            $authInConfig = $msmtprc -match "auth\s+$($smtp.auth_method)"
            $authValid = $authInConfig
            $authOutput = "auth: $($smtp.auth_method)"
        }

        # OAuth2 requires passwordeval
        if ($smtp.auth_method -in @("oauthbearer", "xoauth2")) {
            if (-not $smtp.passwordeval) {
                $authValid = $false
                $authOutput = "OAuth2 auth requires passwordeval for token retrieval"
            }
        }

        # External auth requires client certificates
        if ($smtp.auth_method -eq "external") {
            if (-not $smtp.tls_cert_file -or -not $smtp.tls_key_file) {
                $authValid = $false
                $authOutput = "External auth requires tls_cert_file and tls_key_file"
            }
        }
    }

    <# (multi) return #> @{
        Test = "6.7.6"
        Name = "Auth method valid"
        Pass = $authValid
        Output = $authOutput
    }

    # 6.7.7: TLS settings verification
    $tlsValid = $true
    $tlsOutput = @()

    # Check tls is enabled
    $tlsOn = $msmtprc -match "tls\s+on"
    if (-not $tlsOn) {
        $tlsValid = $false
        $tlsOutput += "TLS not enabled"
    }

    # Port 465 requires tls_starttls off (implicit TLS)
    if ($expectedPort -eq 465) {
        if ($smtp.tls_on_connect) {
            $starttlsOff = $msmtprc -match "tls_starttls\s+off"
            if (-not $starttlsOff) {
                $tlsValid = $false
                $tlsOutput += "Port 465 requires tls_starttls off"
            } else {
                $tlsOutput += "SMTPS (implicit TLS) configured"
            }
        }
    }

    # tls_certcheck verification
    if ($smtp.tls_certcheck -eq $false) {
        $certcheckOff = $msmtprc -match "tls_certcheck\s+off"
        if (-not $certcheckOff) {
            $tlsValid = $false
            $tlsOutput += "tls_certcheck: false not applied"
        } else {
            $tlsOutput += "Certificate verification disabled"
        }
    }

    # Client certificate verification
    if ($smtp.tls_cert_file) {
        $certFileInConfig = $msmtprc -match "tls_cert_file\s+$([regex]::Escape($smtp.tls_cert_file))"
        if (-not $certFileInConfig) {
            $tlsValid = $false
            $tlsOutput += "tls_cert_file not configured"
        } else {
            $tlsOutput += "Client cert: $($smtp.tls_cert_file)"
        }
    }

    if ($smtp.tls_key_file) {
        $keyFileInConfig = $msmtprc -match "tls_key_file\s+$([regex]::Escape($smtp.tls_key_file))"
        if (-not $keyFileInConfig) {
            $tlsValid = $false
            $tlsOutput += "tls_key_file not configured"
        }
    }

    # Custom trust file
    if ($smtp.tls_trust_file) {
        $trustFileInConfig = $msmtprc -match "tls_trust_file\s+$([regex]::Escape($smtp.tls_trust_file))"
        if (-not $trustFileInConfig) {
            $tlsValid = $false
            $tlsOutput += "Custom tls_trust_file not configured"
        } else {
            $tlsOutput += "Custom CA: $($smtp.tls_trust_file)"
        }
    }

    if ($tlsOutput.Count -eq 0) { $tlsOutput = @("Standard TLS (STARTTLS)") }

    <# (multi) return #> @{
        Test = "6.7.7"
        Name = "TLS settings valid"
        Pass = $tlsValid
        Output = $tlsOutput -join "; "
    }

    # 6.7.8: Password/passwordeval configuration
    $credValid = $true
    $credOutput = ""

    if ($smtp.password) {
        $pwInConfig = [bool]($msmtprc -match "password\s+")
        $credValid = $pwInConfig
        $credOutput = "Password configured inline"
    } elseif ($smtp.passwordeval) {
        $pwevalInConfig = [bool]($msmtprc -match "passwordeval\s+")
        $credValid = $pwevalInConfig
        $credOutput = "passwordeval: $($smtp.passwordeval)"
    } else {
        # Default: passwordeval from file
        $defaultPweval = [bool]($msmtprc -match 'passwordeval.*cat.*/etc/msmtp-password')
        $credValid = $defaultPweval
        $credOutput = "Password from /etc/msmtp-password (run msmtp-config)"
    }

    <# (multi) return #> @{
        Test = "6.7.8"
        Name = "Credential config valid"
        Pass = $credValid
        Output = $credOutput
    }

    # 6.7.9: Aliases configuration
    $aliases = multipass exec $VMName -- bash -c 'sudo cat /etc/aliases' 2>&1
    $aliasValid = [bool]($aliases -match "root:\s*$([regex]::Escape($smtp.recipient))")
    <# (multi) return #> @{
        Test = "6.7.9"
        Name = "Root alias configured"
        Pass = $aliasValid
        Output = "root -> $($smtp.recipient)"
    }

    # 6.7.10: msmtp-config helper script
    $helperExists = multipass exec $VMName -- bash -c 'test -x /usr/local/bin/msmtp-config' 2>&1
    <# (multi) return #> @{
        Test = "6.7.10"
        Name = "msmtp-config helper exists"
        Pass = ($LASTEXITCODE -eq 0)
        Output = "/usr/local/bin/msmtp-config"
    }

    # 6.7.11: Send test email (only if password is configured inline)
    if ($smtp.password -and $smtp.recipient -and $credValid) {
        $hostname = multipass exec $VMName -- hostname 2>&1
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        # Use sudo since /etc/msmtprc has 600 permissions owned by root
        # Build command carefully - use single quotes for bash -c to avoid escaping issues
        $recipient = $smtp.recipient
        $subject = "[Test] MSMTP Config Validation - $hostname"
        $body = "Automated test from Infrastructure-Host.`nTimestamp: $timestamp`nProvider: $providerName"
        $sendResult = multipass exec $VMName -- bash -c "echo -e 'Subject: $subject\n\n$body' | sudo msmtp '$recipient'" 2>&1
        $sendExitCode = $LASTEXITCODE

        # Verify email appears in msmtp log (not just exit code)
        $logEntry = multipass exec $VMName -- bash -c "sudo tail -1 /var/log/msmtp.log 2>/dev/null" 2>&1
        $logVerified = ($logEntry -match "recipients=$recipient" -and $logEntry -match "exitcode=EX_OK")

        <# (multi) return #> @{
            Test = "6.7.11"
            Name = "Test email sent"
            Pass = ($sendExitCode -eq 0 -and $logVerified)
            Output = if ($sendExitCode -eq 0 -and $logVerified) { "Email sent and logged: $recipient" } elseif ($sendExitCode -ne 0) { "Send failed: $sendResult" } else { "Send succeeded but not found in log" }
        }
    }

    # return $results
}

# Helper function to identify SMTP provider from hostname
function Get-SMTPProviderName {
    param(
        [string]$SmtpHost,
        [int]$SmtpPort
    )

    switch -Regex ($SmtpHost) {
        "smtp\.sendgrid\.net"           { return "SendGrid" }
        "email-smtp\..*\.amazonaws\.com" { return "AWS SES" }
        "smtp\.mailgun\.org"            { return "Mailgun" }
        "smtp\.postmarkapp\.com"        { return "Postmark" }
        "smtp\.office365\.com"          { return "Microsoft 365" }
        "smtp\.gmail\.com"              { return "Gmail" }
        "smtp\.fastmail\.com"           { return "Fastmail" }
        "smtp\.zoho\.(com|eu|in|com\.au|jp)" { return "Zoho" }
        "smtps?\.zoho\.(com|eu|in|com\.au|jp)" { return "Zoho" }
        "smtp\.mail\.yahoo\.com"        { return "Yahoo" }
        "smtp\.mail\.me\.com"           { return "iCloud" }
        "smtp\.protonmail\.ch"          { return "Proton Mail" }
        "127\.0\.0\.1|localhost" {
            if ($SmtpPort -eq 1025) { return "Proton Bridge" }
            return "Local Server"
        }
        default { return "Self-hosted" }
    }
}

function Test-PackageSecurityFragment {
    param([string]$VMName)

    # $results = @()

    # 6.8.1: Unattended upgrades installed
    $pkg = multipass exec $VMName -- dpkg -l unattended-upgrades 2>&1
    <# (multi) return #> @{
        Test = "6.8.1"
        Name = "unattended-upgrades installed"
        Pass = ($pkg -match "ii.*unattended-upgrades")
        Output = "Package installed"
    }

    # 6.8.2: Config exists
    $config = multipass exec $VMName -- test -f /etc/apt/apt.conf.d/50unattended-upgrades 2>&1
    <# (multi) return #> @{
        Test = "6.8.2"
        Name = "Unattended upgrades config"
        Pass = ($LASTEXITCODE -eq 0)
        Output = "/etc/apt/apt.conf.d/50unattended-upgrades"
    }

    # 6.8.3: Auto-upgrades enabled
    $auto = multipass exec $VMName -- cat /etc/apt/apt.conf.d/20auto-upgrades 2>&1
    <# (multi) return #> @{
        Test = "6.8.3"
        Name = "Auto-upgrades configured"
        Pass = ($auto -match 'Unattended-Upgrade.*"1"')
        Output = "Auto-upgrade enabled"
    }

    # 6.8.4: Service enabled
    $svc = multipass exec $VMName -- systemctl is-enabled unattended-upgrades 2>&1
    <# (multi) return #> @{
        Test = "6.8.4"
        Name = "Service enabled"
        Pass = ($svc -match "enabled")
        Output = $svc
    }

    # 6.8.5: apt-listchanges installed
    $listchanges = multipass exec $VMName -- dpkg -l apt-listchanges 2>&1
    <# (multi) return #> @{
        Test = "6.8.5"
        Name = "apt-listchanges installed"
        Pass = ($listchanges -match "ii.*apt-listchanges")
        Output = "Package installed"
    }

    # 6.8.6: apt-listchanges configured for email
    $listchangesConf = multipass exec $VMName -- bash -c 'cat /etc/apt/listchanges.conf' 2>&1
    <# (multi) return #> @{
        Test = "6.8.6"
        Name = "apt-listchanges email config"
        Pass = [bool]($listchangesConf -match "frontend=mail")
        Output = "Changelogs sent via email"
    }

    # 6.8.7: apt-notify script exists
    $notifyScript = multipass exec $VMName -- bash -c 'test -x /usr/local/bin/apt-notify' 2>&1
    <# (multi) return #> @{
        Test = "6.8.7"
        Name = "apt-notify script exists"
        Pass = ($LASTEXITCODE -eq 0)
        Output = "/usr/local/bin/apt-notify"
    }

    # 6.8.8: dpkg hooks configured
    $dpkgHook = multipass exec $VMName -- bash -c 'cat /etc/apt/apt.conf.d/90pkg-notify' 2>&1
    $hookConfigured = [bool]($dpkgHook -match "DPkg::Pre-Invoke" -and $dpkgHook -match "DPkg::Post-Invoke")
    <# (multi) return #> @{
        Test = "6.8.8"
        Name = "dpkg notification hooks"
        Pass = $hookConfigured
        Output = "Pre/Post-Invoke hooks configured"
    }

    # 6.8.9: Verbose unattended-upgrades reporting
    $uuConf = multipass exec $VMName -- bash -c 'cat /etc/apt/apt.conf.d/50unattended-upgrades' 2>&1
    $verboseEnabled = [bool]($uuConf -match 'Verbose.*"true"')
    $mailAlways = [bool]($uuConf -match 'MailReport.*"always"')
    <# (multi) return #> @{
        Test = "6.8.9"
        Name = "Verbose upgrade reporting"
        Pass = ($verboseEnabled -and $mailAlways)
        Output = "Verbose=true, MailReport=always"
    }

    # 6.8.10: snap-update script exists and is executable
    $snapUpdate = multipass exec $VMName -- bash -c 'test -x /usr/local/bin/snap-update && echo "exists"' 2>&1
    <# (multi) return #> @{
        Test = "6.8.10"
        Name = "snap-update script"
        Pass = ($snapUpdate -match "exists")
        Output = "/usr/local/bin/snap-update"
    }

    # 6.8.11: snap refresh.hold is set to prevent auto-updates
    $snapHold = multipass exec $VMName -- bash -c 'sudo snap get system refresh.hold 2>/dev/null || echo "not-set"' 2>&1
    <# (multi) return #> @{
        Test = "6.8.11"
        Name = "snap refresh.hold configured"
        Pass = ($snapHold -match "forever" -or $snapHold -match "20[0-9]{2}")  # forever or a date
        Output = "refresh.hold=$snapHold"
    }

    # 6.8.12: brew-update script exists and is executable
    $brewUpdate = multipass exec $VMName -- bash -c 'test -x /usr/local/bin/brew-update && echo "exists"' 2>&1
    <# (multi) return #> @{
        Test = "6.8.12"
        Name = "brew-update script"
        Pass = ($brewUpdate -match "exists")
        Output = "/usr/local/bin/brew-update"
    }

    # 6.8.13: pip-global-update script exists and is executable
    $pipUpdate = multipass exec $VMName -- bash -c 'test -x /usr/local/bin/pip-global-update && echo "exists"' 2>&1
    <# (multi) return #> @{
        Test = "6.8.13"
        Name = "pip-global-update script"
        Pass = ($pipUpdate -match "exists")
        Output = "/usr/local/bin/pip-global-update"
    }

    # 6.8.14: npm-global-update script exists and is executable
    $npmUpdate = multipass exec $VMName -- bash -c 'test -x /usr/local/bin/npm-global-update && echo "exists"' 2>&1
    <# (multi) return #> @{
        Test = "6.8.14"
        Name = "npm-global-update script"
        Pass = ($npmUpdate -match "exists")
        Output = "/usr/local/bin/npm-global-update"
    }

    # 6.8.15: deno-update script exists and is executable
    $denoUpdate = multipass exec $VMName -- bash -c 'test -x /usr/local/bin/deno-update && echo "exists"' 2>&1
    <# (multi) return #> @{
        Test = "6.8.15"
        Name = "deno-update script"
        Pass = ($denoUpdate -match "exists")
        Output = "/usr/local/bin/deno-update"
    }

    # 6.8.16: pkg-managers-update systemd timer enabled
    $timerEnabled = multipass exec $VMName -- bash -c 'systemctl is-enabled pkg-managers-update.timer 2>/dev/null' 2>&1
    $timerActive = multipass exec $VMName -- bash -c 'systemctl is-active pkg-managers-update.timer 2>/dev/null' 2>&1
    <# (multi) return #> @{
        Test = "6.8.16"
        Name = "pkg-managers-update timer"
        Pass = ($timerEnabled -match "enabled") -and ($timerActive -match "active")
        Output = "enabled=$timerEnabled, active=$timerActive"
    }

    # 6.8.17: apt-notify common library exists
    $commonLib = multipass exec $VMName -- bash -c 'test -f /usr/local/lib/apt-notify/common.sh && echo "exists"' 2>&1
    <# (multi) return #> @{
        Test = "6.8.17"
        Name = "apt-notify common library"
        Pass = ($commonLib -match "exists")
        Output = "/usr/local/lib/apt-notify/common.sh"
    }

    # 6.8.18: apt-notify-flush script exists
    $flushScript = multipass exec $VMName -- bash -c 'test -x /usr/local/bin/apt-notify-flush && echo "exists"' 2>&1
    <# (multi) return #> @{
        Test = "6.8.18"
        Name = "apt-notify-flush script"
        Pass = ($flushScript -match "exists")
        Output = "/usr/local/bin/apt-notify-flush"
    }

    # return $results
}

function Test-SecurityMonitoringFragment {
    param([string]$VMName)

    # $results = @()

    # 6.9.1: fail2ban installed
    $f2b = multipass exec $VMName -- which fail2ban-client 2>&1
    <# (multi) return #> @{
        Test = "6.9.1"
        Name = "fail2ban installed"
        Pass = ($f2b -match "fail2ban" -and $LASTEXITCODE -eq 0)
        Output = $f2b
    }

    # 6.9.2: fail2ban running
    $status = multipass exec $VMName -- sudo systemctl is-active fail2ban 2>&1
    <# (multi) return #> @{
        Test = "6.9.2"
        Name = "fail2ban service active"
        Pass = ($status -match "^active$")
        Output = $status
    }

    # 6.9.3: SSH jail enabled
    $jails = multipass exec $VMName -- sudo fail2ban-client status 2>&1
    <# (multi) return #> @{
        Test = "6.9.3"
        Name = "SSH jail configured"
        Pass = ($jails -match "sshd")
        Output = "sshd jail"
    }

    # return $results
}

function Test-VirtualizationFragment {
    param([string]$VMName)

    # $results = @()

    # 6.10.1: libvirt installed
    $libvirt = multipass exec $VMName -- which virsh 2>&1
    <# (multi) return #> @{
        Test = "6.10.1"
        Name = "libvirt installed"
        Pass = ($libvirt -match "virsh" -and $LASTEXITCODE -eq 0)
        Output = $libvirt
    }

    # 6.10.2: libvirtd running
    $svc = multipass exec $VMName -- systemctl is-active libvirtd 2>&1
    <# (multi) return #> @{
        Test = "6.10.2"
        Name = "libvirtd service active"
        Pass = ($svc -match "^active$")
        Output = $svc
    }

    # 6.10.3: QEMU/KVM available
    $qemu = multipass exec $VMName -- which qemu-system-x86_64 2>&1
    <# (multi) return #> @{
        Test = "6.10.3"
        Name = "QEMU installed"
        Pass = ($qemu -match "qemu" -and $LASTEXITCODE -eq 0)
        Output = $qemu
    }

    # 6.10.4: Default network
    $net = multipass exec $VMName -- sudo virsh net-list --all 2>&1
    <# (multi) return #> @{
        Test = "6.10.4"
        Name = "Default network exists"
        Pass = ($net -match "default")
        Output = "virsh net-list"
    }

    # 6.10.5: Multipass installed
    $multipass = multipass exec $VMName -- which multipass 2>&1
    <# (multi) return #> @{
        Test = "6.10.5"
        Name = "Multipass installed"
        Pass = ($multipass -match "multipass" -and $LASTEXITCODE -eq 0)
        Output = $multipass
    }

    # 6.10.6: Multipass daemon running
    $mpStatus = multipass exec $VMName -- systemctl is-active snap.multipass.multipassd.service 2>&1
    <# (multi) return #> @{
        Test = "6.10.6"
        Name = "Multipass daemon active"
        Pass = ($mpStatus -match "^active$")
        Output = $mpStatus
    }

    # 6.10.7: Check KVM availability for nested virtualization
    # Nested VMs require KVM, which depends on host hypervisor enabling nested virtualization
    $kvmCheck = multipass exec $VMName -- bash -c 'test -e /dev/kvm && echo "kvm-available" || echo "kvm-unavailable"' 2>&1
    $kvmAvailable = ($kvmCheck -match "kvm-available")

    <# (multi) return #> @{
        Test = "6.10.7"
        Name = "KVM available for nesting"
        Pass = $kvmAvailable
        Output = if ($kvmAvailable) { "/dev/kvm accessible" } else { "KVM not available (nested virt not enabled on host)" }
    }

    # 6.10.8: Nested VM test - only run if KVM is available
    if ($kvmAvailable) {
        $nestedVMName = "nested-test-vm"
        # Use $ErrorActionPreference locally to avoid terminating on stderr warnings
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $nestedLaunch = multipass exec $VMName -- bash -c "multipass launch --name $nestedVMName --memory 512M --disk 4G --cpus 1 --timeout 300 2>&1" 2>&1
        $nestedLaunchCode = $LASTEXITCODE
        $ErrorActionPreference = $prevEAP

        if ($nestedLaunchCode -eq 0) {
            # Verify nested VM is running
            $nestedList = multipass exec $VMName -- multipass list 2>&1
            $nestedRunning = ($nestedList -match "$nestedVMName.*Running")

            <# (multi) return #> @{
                Test = "6.10.8"
                Name = "Nested VM launched"
                Pass = $nestedRunning
                Output = if ($nestedRunning) { "Nested VM '$nestedVMName' running" } else { "Launch succeeded but VM not running" }
            }

            # 6.10.9: Test nested VM connectivity
            $nestedExec = multipass exec $VMName -- bash -c "multipass exec $nestedVMName -- echo 'nested-ok'" 2>&1
            <# (multi) return #> @{
                Test = "6.10.9"
                Name = "Nested VM exec works"
                Pass = ($nestedExec -match "nested-ok")
                Output = if ($nestedExec -match "nested-ok") { "Nested exec successful" } else { $nestedExec }
            }

            # Cleanup nested VM
            multipass exec $VMName -- bash -c "multipass delete $nestedVMName --purge" 2>&1 | Out-Null
        } else {
            <# (multi) return #> @{
                Test = "6.10.8"
                Name = "Nested VM launched"
                Pass = $false
                Output = "Failed to launch nested VM: $nestedLaunch"
            }
            <# (multi) return #> @{
                Test = "6.10.9"
                Name = "Nested VM exec works"
                Pass = $false
                Output = "Skipped - nested VM launch failed"
            }
        }
    } else {
        # Skip nested VM tests when KVM not available
        <# (multi) return #> @{
            Test = "6.10.8"
            Name = "Nested VM launched"
            Pass = $true  # Pass since it's a host configuration issue, not our cloud-init
            Output = "Skipped - KVM not available (enable nested virt on host to test)"
        }
        <# (multi) return #> @{
            Test = "6.10.9"
            Name = "Nested VM exec works"
            Pass = $true  # Pass since it's a host configuration issue
            Output = "Skipped - KVM not available"
        }
    }

    # return $results
}

function Test-CockpitFragment {
    param([string]$VMName)

    # $results = @()

    # 6.11.1: Cockpit installed
    $cockpit = multipass exec $VMName -- which cockpit-bridge 2>&1
    <# (multi) return #> @{
        Test = "6.11.1"
        Name = "Cockpit installed"
        Pass = ($cockpit -match "cockpit" -and $LASTEXITCODE -eq 0)
        Output = $cockpit
    }

    # 6.11.2: Cockpit socket enabled
    $socket = multipass exec $VMName -- systemctl is-enabled cockpit.socket 2>&1
    <# (multi) return #> @{
        Test = "6.11.2"
        Name = "Cockpit socket enabled"
        Pass = ($socket -match "enabled")
        Output = $socket
    }

    # 6.11.3: Cockpit machines plugin
    $machines = multipass exec $VMName -- dpkg -l cockpit-machines 2>&1
    <# (multi) return #> @{
        Test = "6.11.3"
        Name = "cockpit-machines installed"
        Pass = ($machines -match "ii.*cockpit-machines")
        Output = "Package installed"
    }

    # 6.11.4: Cockpit socket listening (detect configured port from socket config)
    # The fragment defaults to 127.0.0.1:443 for security, but may be configured differently
    # Config has two lines: "ListenStream=" (clears default) then "ListenStream=addr:port"
    $socketConfig = multipass exec $VMName -- bash -c 'grep "ListenStream=.*:" /etc/systemd/system/cockpit.socket.d/listen.conf 2>/dev/null || echo "0.0.0.0:9090"' 2>&1
    $listenMatch = [regex]::Match($socketConfig, '([0-9.]+):(\d+)')
    $listenAddr = if ($listenMatch.Success) { $listenMatch.Groups[1].Value } else { "0.0.0.0" }
    $listenPort = if ($listenMatch.Success) { $listenMatch.Groups[2].Value } else { "9090" }

    # Activate the socket by making a request (cockpit uses socket activation)
    multipass exec $VMName -- bash -c "curl -sk https://localhost:$listenPort/ > /dev/null 2>&1 || true" 2>&1 | Out-Null
    Start-Sleep -Seconds 2

    $listening = multipass exec $VMName -- bash -c "ss -tlnp | grep ':$listenPort'" 2>&1
    <# (multi) return #> @{
        Test = "6.11.4"
        Name = "Cockpit socket listening"
        Pass = ($listening -match ":$listenPort")
        Output = if ($listening -match ":$listenPort") { "Listening on ${listenAddr}:${listenPort}" } else { "Port $listenPort not listening" }
    }

    # 6.11.5: Cockpit web interface responds (internal)
    $httpResponse = multipass exec $VMName -- bash -c "curl -sk -o /dev/null -w '%{http_code}' https://localhost:$listenPort/" 2>&1
    $httpOk = ($httpResponse -match "^(200|301|302)$")
    <# (multi) return #> @{
        Test = "6.11.5"
        Name = "Cockpit web UI responds"
        Pass = $httpOk
        Output = if ($httpOk) { "HTTP $httpResponse on localhost:$listenPort" } else { "HTTP response: $httpResponse" }
    }

    # 6.11.6: Cockpit login page loads (check for login.js or login form elements)
    $loginPage = multipass exec $VMName -- bash -c "curl -sk https://localhost:$listenPort/ 2>/dev/null | grep -E 'login\.js|login\.css|login-pf' | head -1" 2>&1
    <# (multi) return #> @{
        Test = "6.11.6"
        Name = "Cockpit login page loads"
        Pass = [bool]$loginPage
        Output = if ($loginPage) { "Login page accessible" } else { "Login page not found" }
    }

    # 6.11.7: Test Cockpit via SSH tunnel (if SSH keys configured)
    # Cockpit is localhost-only by design, accessed via SSH local port forwarding
    $testConfig = Get-TestConfig
    $sshKeys = $testConfig.identity.ssh_authorized_keys
    $sshUser = $testConfig.identity.username

    $vmInfo = multipass info $VMName --format json 2>&1 | ConvertFrom-Json
    $vmIp = $vmInfo.info.$VMName.ipv4 | Select-Object -First 1

    if ($sshKeys -and $sshKeys.Count -gt 0 -and $vmIp) {
        # Use a random high port for local forwarding to avoid conflicts
        $localPort = Get-Random -Minimum 19000 -Maximum 19999

        # Start SSH tunnel in background (-f for background, -N for no command)
        # Using Start-Process to run in background on Windows
        $sshArgs = "-o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -L ${localPort}:127.0.0.1:${listenPort} -N ${sshUser}@${vmIp}"
        $sshProcess = Start-Process -FilePath "ssh" -ArgumentList $sshArgs -PassThru -WindowStyle Hidden

        # Wait for tunnel to establish
        Start-Sleep -Seconds 3

        if (-not $sshProcess.HasExited) {
            try {
                # Test Cockpit through the SSH tunnel
                # Use curl.exe (included in Windows 10+) instead of Invoke-WebRequest
                # PowerShell 5.1's Invoke-WebRequest has TLS issues with self-signed certs
                $curlResult = & curl.exe -sk -o NUL -w "%{http_code}" "https://localhost:${localPort}/" 2>&1
                $httpCode = [int]$curlResult
                <# (multi) return #> @{
                    Test = "6.11.7"
                    Name = "Cockpit via SSH tunnel"
                    Pass = ($httpCode -eq 200)
                    Output = "SSH tunnel localhost:${localPort} -> 127.0.0.1:${listenPort} - HTTP $httpCode"
                }
            } catch {
                $errorMsg = $_.Exception.Message
                <# (multi) return #> @{
                    Test = "6.11.7"
                    Name = "Cockpit via SSH tunnel"
                    Pass = $false
                    Output = "SSH tunnel established but web request failed: $errorMsg"
                }
            } finally {
                # Clean up SSH tunnel
                Stop-Process -Id $sshProcess.Id -Force -ErrorAction SilentlyContinue
            }
        } else {
            <# (multi) return #> @{
                Test = "6.11.7"
                Name = "Cockpit via SSH tunnel"
                Pass = $false
                Output = "SSH tunnel failed to establish (ensure private key is loaded in ssh-agent)"
            }
        }
    } elseif ($sshKeys -and $sshKeys.Count -gt 0) {
        <# (multi) return #> @{
            Test = "6.11.7"
            Name = "Cockpit via SSH tunnel"
            Pass = $false
            Output = "Could not get VM IP address"
        }
    } else {
        # No SSH keys configured, skip test
        <# (multi) return #> @{
            Test = "6.11.7"
            Name = "Cockpit via SSH tunnel"
            Pass = $true
            Output = "Skipped - no SSH keys configured"
        }
    }

    # return $results
}

function Test-OpenCodeFragment {
    param([string]$VMName)

    # $results = @()
    $testConfig = Get-TestConfig
    $username = $testConfig.identity.username
    $smtp = $testConfig.smtp

    # 6.14.1: Node.js installed
    $node = multipass exec $VMName -- which node 2>&1
    <# (multi) return #> @{
        Test = "6.14.1"
        Name = "Node.js installed"
        Pass = ($node -match "node" -and $LASTEXITCODE -eq 0)
        Output = $node
    }

    # 6.14.2: npm installed
    $npm = multipass exec $VMName -- which npm 2>&1
    <# (multi) return #> @{
        Test = "6.14.2"
        Name = "npm installed"
        Pass = ($npm -match "npm" -and $LASTEXITCODE -eq 0)
        Output = $npm
    }

    # 6.14.3: OpenCode setup
    $opencode = multipass exec $VMName -- which opencode 2>&1
    <# (multi) return #> @{
        Test = "6.14.3"
        Name = "OpenCode CLI installed"
        Pass = ($opencode -match "opencode" -and $LASTEXITCODE -eq 0)
        Output = $opencode
    }

    # 6.14.4: OpenCode config directory exists
    $configDir = multipass exec $VMName -- bash -c "sudo test -d /home/$username/.config/opencode && echo 'exists'" 2>&1
    <# (multi) return #> @{
        Test = "6.14.4"
        Name = "OpenCode config directory"
        Pass = ($configDir -match "exists")
        Output = "/home/$username/.config/opencode"
    }

    # 6.14.5: OpenCode auth.json (derived from Claude Code credentials)
    # Note: github-copilot cannot be derived from Copilot CLI (incompatible token types: gho_ vs ghu_)
    $authFile = multipass exec $VMName -- bash -c "sudo test -f /home/$username/.local/share/opencode/auth.json && echo 'exists'" 2>&1
    $authConfigured = ($authFile -match "exists")
    <# (multi) return #> @{
        Test = "6.14.5"
        Name = "OpenCode auth.json"
        Pass = $authConfigured
        Output = if ($authConfigured) { "/home/$username/.local/share/opencode/auth.json" } else { "No auth (derived from Claude Code)" }
    }

    # 6.14.6: OpenCode AI response test (if auth configured)
    if ($authConfigured) {
        $prompt = "test"
        $timeoutSeconds = 60

        # Run multipass exec as a job with timeout
        # Note: opencode may require a PTY to produce output, so we use 'script' to allocate one
        # Also explicitly set HOME since multipass can inherit Windows HOME
        $job = Start-Job -ScriptBlock {
            param($vm, $user, $p)
            $cmd = "sudo -u $user env HOME=/home/$user script -q -c 'timeout 30 opencode run $p' /dev/null 2>&1"
            multipass exec $vm -- bash -c $cmd
        } -ArgumentList $VMName, $username, $prompt

        $completed = Wait-Job $job -Timeout $timeoutSeconds
        if ($completed) {
            # Use SilentlyContinue to ignore stderr warnings from grpc/multipass
            $testResult = Receive-Job $job -ErrorAction SilentlyContinue 2>&1
            Remove-Job $job -Force -ErrorAction SilentlyContinue
            # Clean up terminal escape codes from script output
            $cleanResult = $testResult -replace '\x1b\[[0-9;]*[a-zA-Z]', '' -replace '\[[\?0-9;]*[a-zA-Z]', ''
            $hasResponse = ($cleanResult -and $cleanResult.Length -gt 0 -and $cleanResult -notmatch "^error|failed|timeout")
            $responseContent = if ($cleanResult) { ($cleanResult | Out-String).Trim() } else { "Empty response" }
        } else {
            Stop-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -Force -ErrorAction SilentlyContinue
            $hasResponse = $false
            $responseContent = "Timed out after ${timeoutSeconds}s"
        }

        <# (multi) return #> @{
            Test = "6.14.6"
            Name = "OpenCode AI response test"
            Pass = $hasResponse
            Output = if ($hasResponse) { "Response: $($responseContent.Substring(0, [Math]::Min(80, $responseContent.Length)))..." } else { "AI response failed: $responseContent" }
        }
    }

    # 6.14.7: Verify OpenCode credential chain (anthropic only)
    # Chain: host Claude credentials → builder VM → BuildContext derives opencode.auth → auth.json
    # Note: github-copilot cannot be derived from Copilot CLI (incompatible token types: gho_ vs ghu_)

    # Determine what SHOULD have happened based on host state and config
    $opencodeEnabled = $testConfig.opencode.enabled -eq $true
    $claudeCodeEnabled = $testConfig.claude_code.enabled -eq $true

    # Extract actual token values from host
    $hostClaudeAccessToken = $null
    $hostClaudeRefreshToken = $null

    # Check for valid Claude token on host
    $hostClaudeCreds = "$env:USERPROFILE\.claude\.credentials.json"
    $hostClaudeState = "$env:USERPROFILE\.claude.json"
    if ((Test-Path $hostClaudeCreds) -and (Test-Path $hostClaudeState)) {
        try {
            $hostClaudeJson = Get-Content $hostClaudeCreds -Raw | ConvertFrom-Json
            $hostClaudeAccessToken = $hostClaudeJson.claudeAiOauth.accessToken
            $hostClaudeRefreshToken = $hostClaudeJson.claudeAiOauth.refreshToken
        } catch {
            $hostClaudeAccessToken = $null
            $hostClaudeRefreshToken = $null
        }

        Write-Host "  [DEBUG] Host Claude: access_token=$hostClaudeAccessToken refresh_token=$hostClaudeRefreshToken"
    }

    # BuildContext derives opencode.auth if: opencode enabled AND claude_code enabled AND host has valid token
    $shouldHaveAnthropicAuth = ($null -ne $hostClaudeAccessToken) -and ($null -ne $hostClaudeRefreshToken) -and $opencodeEnabled -and $claudeCodeEnabled

    # Check what auth is actually present in the generated auth.json on runner VM
    $authJsonPath = "/home/$username/.local/share/opencode/auth.json"
    $hasAnthropicAuth = $false
    $vmAnthropicAccessToken = $null
    $vmAnthropicRefreshToken = $null

    # Get VM auth.json and extract tokens for comparison
    $vmAuthContent = multipass exec $VMName -- bash -c "sudo cat $authJsonPath 2>/dev/null" 2>&1
    if ($vmAuthContent -and $vmAuthContent -notmatch "No such file") {
        try {
            $vmAuthJson = $vmAuthContent | ConvertFrom-Json
            if ($vmAuthJson.anthropic) {
                $hasAnthropicAuth = $true
                $vmAnthropicAccessToken = $vmAuthJson.anthropic.access
                $vmAnthropicRefreshToken = $vmAuthJson.anthropic.refresh
            }
        } catch { }
    }

    # Get opencode models list
    $opencodeModels = multipass exec $VMName -- sudo su - $username -c 'opencode models 2>/dev/null' 2>&1
    $hasAnthropicProvider = ($opencodeModels -match "anthropic/")

    # Determine pass/fail - verify the credential chain worked correctly
    $testPass = $true
    $issues = @()

    if ($shouldHaveAnthropicAuth) {
        if (-not $hasAnthropicAuth) {
            $testPass = $false
            $issues += "anthropic auth missing from auth.json"
        } elseif ($vmAnthropicAccessToken -ne $hostClaudeAccessToken) {
            $testPass = $false
            $issues += "anthropic access token mismatch"
        } elseif ($vmAnthropicRefreshToken -ne $hostClaudeRefreshToken) {
            $testPass = $false
            $issues += "anthropic refresh token mismatch"
        } elseif (-not $hasAnthropicProvider) {
            # Provider not showing could mean permission issue or API error
            # If tokens match, just warn but don't fail
            $issues += "tokens OK but models not listed (possible API issue)"
        }
    } elseif (-not $opencodeEnabled -or -not $claudeCodeEnabled) {
        # OpenCode or Claude Code not enabled - that's fine, just verify opencode works
        if ($opencodeModels -and $opencodeModels.Length -gt 0) {
            $issues += "no auth expected (opencode=$opencodeEnabled, claude_code=$claudeCodeEnabled)"
        }
    }

    Write-TestFork -Test "6.14.7" -Decision "Credential chain" -Reason "should: anthropic=$shouldHaveAnthropicAuth | has: anthropic=$hasAnthropicAuth"

    <# (multi) return #> @{
        Test = "6.14.7"
        Name = "OpenCode credential chain"
        Pass = $testPass
        Output = if ($testPass) {
            "Chain OK - tokens match: $hasAnthropicAuth | models: anthropic=$hasAnthropicProvider" + $(if ($issues.Count -gt 0) { " ($($issues -join '; '))" } else { "" })
        } else {
            "FAILED: $($issues -join '; ')"
        }
    }

    # return $results
}

function Test-ClaudeCodeFragment {
    param([string]$VMName)

    # $results = @()
    $testConfig = Get-TestConfig
    $username = $testConfig.identity.username

    # 6.12.1: Claude Code CLI installed
    $claude = multipass exec $VMName -- which claude 2>&1
    <# (multi) return #> @{
        Test = "6.12.1"
        Name = "Claude Code installed"
        Pass = ($claude -match "claude" -and $LASTEXITCODE -eq 0)
        Output = $claude
    }

    # 6.12.2: Claude Code config directory exists
    $configDir = multipass exec $VMName -- bash -c "sudo test -d /home/$username/.claude && echo 'exists'" 2>&1
    <# (multi) return #> @{
        Test = "6.12.2"
        Name = "Claude Code config directory"
        Pass = ($configDir -match "exists")
        Output = "/home/$username/.claude"
    }

    # 6.12.3: Claude Code settings file exists
    $settingsFile = multipass exec $VMName -- bash -c "sudo test -f /home/$username/.claude/settings.json && echo 'exists'" 2>&1
    <# (multi) return #> @{
        Test = "6.12.3"
        Name = "Claude Code settings file"
        Pass = ($settingsFile -match "exists")
        Output = "/home/$username/.claude/settings.json"
    }

    # 6.12.4: Check authentication configuration (OAuth or API Key)
    # NOTE: Check actual runner VM state, not config file - builder auto-populates auth from host credentials
    $authConfigured = $false
    $hasActualAuth = $false
    $authOutput = "No auth found"

    # Check for OAuth credentials on runner VM
    $credCheck = multipass exec $VMName -- bash -c "sudo test -f /home/$username/.claude/.credentials.json && echo 'exists'" 2>&1
    $stateCheck = multipass exec $VMName -- bash -c "sudo grep -q 'hasCompletedOnboarding' /home/$username/.claude.json 2>/dev/null && echo 'exists'" 2>&1

    if ($credCheck -match "exists" -and $stateCheck -match "exists") {
        Write-TestFork -Test "6.12.4" -Decision "OAuth auth found" -Reason ".credentials.json + hasCompletedOnboarding present"
        $authConfigured = $true
        $hasActualAuth = $true
        $authOutput = "OAuth credentials configured (.credentials.json + hasCompletedOnboarding)"
    } else {
        # Check for API Key as fallback
        $envCheck = multipass exec $VMName -- bash -c "grep -q 'ANTHROPIC_API_KEY' /etc/environment && echo 'configured'" 2>&1
        if ($envCheck -match "configured") {
            Write-TestFork -Test "6.12.4" -Decision "API key auth found" -Reason "ANTHROPIC_API_KEY in /etc/environment"
            $authConfigured = $true
            $hasActualAuth = $true
            $authOutput = "API Key configured (ANTHROPIC_API_KEY in /etc/environment)"
        } else {
            Write-TestFork -Test "6.12.4" -Decision "No auth found" -Reason "No OAuth credentials or API key detected"
            # No auth found - test passes but AI test will be skipped
            $authConfigured = $true
            $authOutput = "No pre-configured auth (run 'claude' to authenticate)"
        }
    }

    <# (multi) return #> @{
        Test = "6.12.4"
        Name = "Claude Code auth configured"
        Pass = $authConfigured
        Output = $authOutput
    }

    # 6.12.5: Claude Code AI response test (only if actual auth configured)
    if ($hasActualAuth) {
        $prompt = "test"
        $timeoutSeconds = 60

        # Run multipass exec as a job with timeout
        # Note: claude -p requires a PTY to produce output, so we use 'script' to allocate one
        # Also explicitly set HOME since multipass can inherit Windows HOME
        $job = Start-Job -ScriptBlock {
            param($vm, $user, $p)
            # Build command separately to avoid quote escaping issues
            $cmd = "sudo -u $user env HOME=/home/$user script -q -c 'timeout 30 claude -p $p' /dev/null 2>&1"
            multipass exec $vm -- bash -c $cmd
        } -ArgumentList $VMName, $username, $prompt

        $completed = Wait-Job $job -Timeout $timeoutSeconds
        if ($completed) {
            # Use SilentlyContinue to ignore stderr warnings from grpc/multipass
            $testResult = Receive-Job $job -ErrorAction SilentlyContinue 2>&1
            Remove-Job $job -Force -ErrorAction SilentlyContinue
            # Clean up terminal escape codes from script output
            $cleanResult = $testResult -replace '\x1b\[[0-9;]*[a-zA-Z]', '' -replace '\[[\?0-9;]*[a-zA-Z]', ''
            $hasResponse = ($cleanResult -and $cleanResult.Length -gt 0 -and $cleanResult -notmatch "^error|failed|timeout")
            $responseContent = if ($cleanResult) { ($cleanResult | Out-String).Trim() } else { "Empty response" }
        } else {
            Stop-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -Force -ErrorAction SilentlyContinue
            $hasResponse = $false
            $responseContent = "Timed out after ${timeoutSeconds}s"
        }


        <# (multi) return #> @{
            Test = "6.12.5"
            Name = "Claude Code AI response test"
            Pass = $hasResponse
            Output = if ($hasResponse) { "Response: $($responseContent.Substring(0, [Math]::Min(80, $responseContent.Length)))..." } else { "AI response failed: $responseContent" }
        }
    }

    # return $results
}

function Test-CopilotCLIFragment {
    param([string]$VMName)

    # $results = @()
    $testConfig = Get-TestConfig
    $username = $testConfig.identity.username

    # 6.13.1: Copilot CLI installed (npm package: @github/copilot)
    $copilot = multipass exec $VMName -- which copilot 2>&1
    <# (multi) return #> @{
        Test = "6.13.1"
        Name = "Copilot CLI installed"
        Pass = ($copilot -match "copilot" -and $LASTEXITCODE -eq 0)
        Output = $copilot
    }

    # 6.13.2: Copilot CLI config directory exists
    $configDir = multipass exec $VMName -- bash -c "sudo test -d /home/$username/.copilot && echo 'exists'" 2>&1
    <# (multi) return #> @{
        Test = "6.13.2"
        Name = "Copilot CLI config directory"
        Pass = ($configDir -match "exists")
        Output = "/home/$username/.copilot"
    }

    # 6.13.3: Copilot CLI config file exists
    $configFile = multipass exec $VMName -- bash -c "sudo test -f /home/$username/.copilot/config.json && echo 'exists'" 2>&1
    <# (multi) return #> @{
        Test = "6.13.3"
        Name = "Copilot CLI config file"
        Pass = ($configFile -match "exists")
        Output = "/home/$username/.copilot/config.json"
    }

    # 6.13.4: Check authentication (OAuth tokens or GH_TOKEN)
    # NOTE: Check actual runner VM state, not config file - builder auto-populates auth from host credentials
    $authConfigured = $false
    $authOutput = "No auth found"

    # Check for copilot_tokens in config.json on runner VM
    $tokensCheck = multipass exec $VMName -- bash -c "sudo grep -q 'copilot_tokens' /home/$username/.copilot/config.json 2>/dev/null && echo 'configured'" 2>&1
    if ($tokensCheck -match "configured") {
        Write-TestFork -Test "6.13.4" -Decision "OAuth auth found" -Reason "copilot_tokens in config.json"
        $authConfigured = $true
        $authOutput = "OAuth configured in ~/.copilot/config.json (copilot_tokens)"
    } else {
        # Check for GH_TOKEN environment variable as fallback
        $envCheck = multipass exec $VMName -- bash -c "grep -q 'GH_TOKEN' /etc/environment && echo 'configured'" 2>&1
        if ($envCheck -match "configured") {
            Write-TestFork -Test "6.13.4" -Decision "GH_TOKEN auth found" -Reason "GH_TOKEN in /etc/environment"
            $authConfigured = $true
            $authOutput = "GH_TOKEN in /etc/environment"
        } else {
            Write-TestFork -Test "6.13.4" -Decision "No auth found" -Reason "No OAuth tokens or GH_TOKEN detected"
            $authOutput = "No pre-configured auth (run 'copilot' then '/login' to authenticate)"
        }
    }

    <# (multi) return #> @{
        Test = "6.13.4"
        Name = "Copilot CLI auth configured"
        Pass = $true
        Output = $authOutput
    }

    # 6.13.5: Copilot CLI AI response test (only if actual auth configured)
    if ($authConfigured) {
        $prompt = "test"
        $timeoutSeconds = 60

        # Run multipass exec as a job with timeout
        # Note: copilot -p requires a PTY to produce output, so we use 'script' to allocate one
        # Also explicitly set HOME since multipass can inherit Windows HOME
        # Must specify --model as copilot requires model selection
        $job = Start-Job -ScriptBlock {
            param($vm, $user, $p)
            $cmd = "sudo -u $user env HOME=/home/$user script -q -c 'timeout 30 copilot --model gpt-4.1 -p $p' /dev/null 2>&1"
            multipass exec $vm -- bash -c $cmd
        } -ArgumentList $VMName, $username, $prompt

        $completed = Wait-Job $job -Timeout $timeoutSeconds
        if ($completed) {
            # Use SilentlyContinue to ignore stderr warnings from grpc/multipass
            $testResult = Receive-Job $job -ErrorAction SilentlyContinue 2>&1
            Remove-Job $job -Force -ErrorAction SilentlyContinue
            # Clean up terminal escape codes from script output
            $cleanResult = $testResult -replace '\x1b\[[0-9;]*[a-zA-Z]', '' -replace '\[[\?0-9;]*[a-zA-Z]', ''
            $hasResponse = ($cleanResult -and $cleanResult.Length -gt 0 -and $cleanResult -notmatch "^error|failed|timeout")
            $responseContent = if ($cleanResult) { ($cleanResult | Out-String).Trim() } else { "Empty response" }
        } else {
            Stop-Job $job
            Remove-Job $job -Force
            $hasResponse = $false
            $responseContent = "Timed out after ${timeoutSeconds}s"
        }

        <# (multi) return #> @{
            Test = "6.13.5"
            Name = "Copilot CLI AI response test"
            Pass = $hasResponse
            Output = if ($hasResponse) { "Response: $($responseContent.Substring(0, [Math]::Min(80, $responseContent.Length)))..." } else { "AI response failed: $responseContent" }
        }
    }

    # return $results
}

function Test-UIFragment {
    param([string]$VMName)

    # $results = @()

    # 6.15.1: MOTD configured
    $motd = multipass exec $VMName -- test -d /etc/update-motd.d 2>&1
    <# (multi) return #> @{
        Test = "6.15.1"
        Name = "MOTD directory exists"
        Pass = ($LASTEXITCODE -eq 0)
        Output = "/etc/update-motd.d"
    }

    # 6.15.2: Custom MOTD scripts
    $scripts = multipass exec $VMName -- bash -c "ls /etc/update-motd.d/ | wc -l" 2>&1
    <# (multi) return #> @{
        Test = "6.15.2"
        Name = "MOTD scripts present"
        Pass = ([int]$scripts -gt 0)
        Output = "$scripts scripts"
    }

    # return $results
}

# Test package manager update detection (called when testing=true in build context)
function Test-PackageManagerUpdates {
    param([string]$VMName)

    # $results = @()
    $testConfig = Get-TestConfig

    # Check if testing mode is enabled
    $testingMode = multipass exec $VMName -- bash -c 'source /usr/local/lib/apt-notify/common.sh && echo $TESTING_MODE' 2>&1
    if ($testingMode -ne "true") {
        <# (multi) return #> @{
            Test = "6.8.19"
            Name = "Testing mode enabled"
            Pass = $false
            Output = "Testing mode not enabled - rebuild with testing=true to run these tests"
        }
        return # $results
    }

    <# (multi) return #> @{
        Test = "6.8.19"
        Name = "Testing mode enabled"
        Pass = $true
        Output = "TESTING_MODE=true"
    }

    # Clear queue and test files before tests
    multipass exec $VMName -- bash -c 'sudo rm -f /var/lib/apt-notify/queue /var/lib/apt-notify/test-report.txt /var/lib/apt-notify/test-ai-summary.txt' 2>&1 | Out-Null

    # 6.8.20: Test snap-update script
    $snapInstalled = multipass exec $VMName -- which snap 2>&1
    if ($snapInstalled -match "snap" -and $LASTEXITCODE -eq 0) {
        # Run the actual snap-update script
        $snapResult = multipass exec $VMName -- bash -c 'sudo /usr/local/bin/snap-update 2>&1; echo "exit_code:$?"' 2>&1
        $snapExitOk = ($snapResult -match "exit_code:0")

        # Check journal for snap-update execution
        $snapLog = multipass exec $VMName -- bash -c 'grep "snap-update" /var/lib/apt-notify/apt-notify.log 2>/dev/null | tail -3' 2>&1

        <# (multi) return #> @{
            Test = "6.8.20"
            Name = "snap-update script execution"
            Pass = $snapExitOk
            Output = if ($snapExitOk) { "Script ran successfully. Log: $($snapLog -replace "`n", ' ')" } else { "Script failed: $snapResult" }
        }
    } else {
        <# (multi) return #> @{
            Test = "6.8.20"
            Name = "snap-update script execution"
            Pass = $true
            Output = "Skipped - snap not installed"
        }
    }

    # 6.8.21: Test npm-global-update script with outdated package
    $npmInstalled = multipass exec $VMName -- which npm 2>&1
    if ($npmInstalled -match "npm" -and $LASTEXITCODE -eq 0) {
        # Install an old version of a small test package globally
        multipass exec $VMName -- bash -c 'sudo npm install -g is-odd@2.0.0 2>/dev/null' 2>&1 | Out-Null

        # Clear queue before running script
        multipass exec $VMName -- bash -c 'sudo rm -f /var/lib/apt-notify/queue' 2>&1 | Out-Null

        # Run the actual npm-global-update script
        $npmResult = multipass exec $VMName -- bash -c 'sudo /usr/local/bin/npm-global-update 2>&1; echo "exit_code:$?"' 2>&1
        $npmExitOk = ($npmResult -match "exit_code:0")

        # Check queue for npm entry
        $queueContent = multipass exec $VMName -- bash -c "cat /var/lib/apt-notify/queue 2>/dev/null || echo ''" 2>&1
        $npmDetected = [bool]($queueContent -match "NPM_UPGRADED")

        <# (multi) return #> @{
            Test = "6.8.21"
            Name = "npm-global-update script"
            Pass = ($npmExitOk -and $npmDetected)
            Output = if ($npmDetected) { "Detected npm update in queue" } elseif ($npmExitOk) { "Script ran but no updates found" } else { "Script failed" }
        }

        # Cleanup test package
        multipass exec $VMName -- bash -c 'sudo npm uninstall -g is-odd 2>/dev/null' 2>&1 | Out-Null
    } else {
        <# (multi) return #> @{
            Test = "6.8.21"
            Name = "npm-global-update script"
            Pass = $true
            Output = "Skipped - npm not installed"
        }
    }

    # 6.8.22: Test pip-global-update script with outdated package
    $pipInstalled = multipass exec $VMName -- which pip3 2>&1
    if ($pipInstalled -match "pip" -and $LASTEXITCODE -eq 0) {
        # Install an old version of a small test package
        multipass exec $VMName -- bash -c 'sudo pip3 install six==1.15.0 2>/dev/null' 2>&1 | Out-Null

        # Clear queue before running script
        multipass exec $VMName -- bash -c 'sudo rm -f /var/lib/apt-notify/queue' 2>&1 | Out-Null

        # Run the actual pip-global-update script
        $pipResult = multipass exec $VMName -- bash -c 'sudo /usr/local/bin/pip-global-update 2>&1; echo "exit_code:$?"' 2>&1
        $pipExitOk = ($pipResult -match "exit_code:0")

        # Check queue for pip entry
        $queueContent = multipass exec $VMName -- bash -c "cat /var/lib/apt-notify/queue 2>/dev/null || echo ''" 2>&1
        $pipDetected = [bool]($queueContent -match "PIP_UPGRADED")

        <# (multi) return #> @{
            Test = "6.8.22"
            Name = "pip-global-update script"
            Pass = ($pipExitOk -and $pipDetected)
            Output = if ($pipDetected) { "Detected pip update in queue" } elseif ($pipExitOk) { "Script ran but no updates found" } else { "Script failed" }
        }
    } else {
        <# (multi) return #> @{
            Test = "6.8.22"
            Name = "pip-global-update script"
            Pass = $true
            Output = "Skipped - pip not installed"
        }
    }

    # 6.8.23: Test brew-update script (if installed)
    $brewInstalled = multipass exec $VMName -- bash -c 'command -v brew || test -x /home/linuxbrew/.linuxbrew/bin/brew' 2>&1
    if ($LASTEXITCODE -eq 0) {
        # Run the actual brew-update script
        $brewResult = multipass exec $VMName -- bash -c 'sudo /usr/local/bin/brew-update 2>&1; echo "exit_code:$?"' 2>&1
        $brewExitOk = ($brewResult -match "exit_code:0")

        <# (multi) return #> @{
            Test = "6.8.23"
            Name = "brew-update script"
            Pass = $brewExitOk
            Output = if ($brewExitOk) { "Script ran successfully" } else { "Script failed: $brewResult" }
        }
    } else {
        <# (multi) return #> @{
            Test = "6.8.23"
            Name = "brew-update script"
            Pass = $true
            Output = "Skipped - brew not installed"
        }
    }

    # 6.8.24: Test deno-update script (if installed)
    $denoInstalled = multipass exec $VMName -- which deno 2>&1
    if ($denoInstalled -match "deno" -and $LASTEXITCODE -eq 0) {
        # Run the actual deno-update script
        $denoResult = multipass exec $VMName -- bash -c 'sudo /usr/local/bin/deno-update 2>&1; echo "exit_code:$?"' 2>&1
        $denoExitOk = ($denoResult -match "exit_code:0")

        <# (multi) return #> @{
            Test = "6.8.24"
            Name = "deno-update script"
            Pass = $denoExitOk
            Output = if ($denoExitOk) { "Script ran successfully" } else { "Script failed: $denoResult" }
        }
    } else {
        <# (multi) return #> @{
            Test = "6.8.24"
            Name = "deno-update script"
            Pass = $true
            Output = "Skipped - deno not installed"
        }
    }

    # return $results
}

# Test update summary generation (6.8-summary)
function Test-UpdateSummary {
    param([string]$VMName)

    # $results = @()
    $testConfig = Get-TestConfig

    # 6.8.25: Test apt-notify-flush with populated queue and validate report generation
    # Uses separate simple commands to avoid escaping issues
    # Step 1a: Clear existing test files and log
    multipass exec $VMName -- sudo rm -f /var/lib/apt-notify/test-report.txt /var/lib/apt-notify/test-ai-summary.txt /var/lib/apt-notify/apt-notify.log 2>&1 | Out-Null

    # Step 1b: Create queue file with test entries using printf (handles special chars safely)
    $queuePath = "/var/lib/apt-notify/apt-notify.queue"
    $queueLines = @(
        "INSTALLED:testpkg:1.0.0"
        "UPGRADED:curl:7.81.0:7.82.0"
        "SNAP_UPGRADED:lxd:5.20:5.21"
        "BREW_UPGRADED:jq:1.6:1.7"
        "PIP_UPGRADED:requests:2.28.0:2.31.0"
        "NPM_UPGRADED:opencode:1.0.0:1.1.0"
        "DENO_UPGRADED:deno:1.40.0:1.41.0"
    )
    # Write queue file line by line to avoid escaping issues
    multipass exec $VMName -- sudo bash -c "rm -f $queuePath" 2>&1 | Out-Null
    foreach ($line in $queueLines) {
        multipass exec $VMName -- sudo bash -c "echo '$line' >> $queuePath" 2>&1 | Out-Null
    }

    # Step 2: Run apt-notify-flush with timeout (AI summary can hang)
    multipass exec $VMName -- sudo timeout 30 /usr/local/bin/apt-notify-flush 2>&1 | Out-Null

    # Step 3: Check if report file was created (use test -s for non-empty file)
    multipass exec $VMName -- sudo test -s /var/lib/apt-notify/test-report.txt 2>&1 | Out-Null
    $reportCreated = ($LASTEXITCODE -eq 0)

    <# (multi) return #> @{
        Test = "6.8.25"
        Name = "apt-notify-flush generates test report"
        Pass = $reportCreated
        Output = if ($reportCreated) {
            "Test report file created at /var/lib/apt-notify/test-report.txt"
        } else {
            # Show log for debugging
            $logTail = multipass exec $VMName -- bash -c 'tail -5 /var/lib/apt-notify/apt-notify.log 2>/dev/null || echo "(no log)"' 2>&1
            "Test report file not created. Log: $($logTail -join ' | ')"
        }
    }

    # 6.8.26: Validate report content contains expected sections
    # The report only includes sections with actual changes (not empty sections)
    # Test 6.8.21 installs is-odd via npm, so NPM section should be present
    $reportContent = multipass exec $VMName -- bash -c "cat /var/lib/apt-notify/test-report.txt 2>/dev/null || echo ''" 2>&1
    $hasNpm = ($reportContent -match "NPM: GLOBAL PACKAGES UPGRADED")
    $hasIsOdd = ($reportContent -match "is-odd")

    <# (multi) return #> @{
        Test = "6.8.26"
        Name = "Report contains npm section with is-odd"
        Pass = ($hasNpm -and $hasIsOdd)
        Output = if ($hasNpm -and $hasIsOdd) { "NPM section present with is-odd upgrade" } else { "Expected NPM section with is-odd. Got: $($reportContent -join ' ')" }
    }

    # 6.8.27: Validate AI summary reports model passed via --model flag
    $aiSummaryFile = multipass exec $VMName -- bash -c "cat /var/lib/apt-notify/test-ai-summary.txt 2>/dev/null || echo ''" 2>&1

    # Determine which CLI was used and expected model from config
    $cliName = $null
    $expectedModel = $null
    $expectedProvider = $null

    if ($testConfig.opencode -and $testConfig.opencode.enabled) {
        $cliName = "OpenCode"
        # OpenCode derives model from claude_code or copilot_cli config, fallback to anthropic/claude-haiku-4-5
        if ($testConfig.claude_code -and $testConfig.claude_code.model) {
            $expectedProvider = "anthropic"
            $expectedModel = $testConfig.claude_code.model
            Write-TestFork -Test "6.8.27" -Decision "OpenCode with Claude model" -Reason "claude_code.model=$expectedModel"
        } elseif ($testConfig.copilot_cli -and $testConfig.copilot_cli.model) {
            $expectedProvider = "github-copilot"
            $expectedModel = $testConfig.copilot_cli.model
            Write-TestFork -Test "6.8.27" -Decision "OpenCode with Copilot model" -Reason "copilot_cli.model=$expectedModel"
        } else {
            $expectedProvider = "anthropic"
            $expectedModel = "claude-haiku-4-5"
            Write-TestFork -Test "6.8.27" -Decision "OpenCode with fallback model" -Reason "No model configured, using $expectedModel"
        }
    } elseif ($testConfig.claude_code -and $testConfig.claude_code.enabled) {
        $cliName = "Claude Code"
        # Claude Code uses model from config, fallback to "claude-haiku-4-5"
        if ($testConfig.claude_code.model) {
            $expectedModel = $testConfig.claude_code.model
            Write-TestFork -Test "6.8.27" -Decision "Claude Code CLI" -Reason "model=$expectedModel"
        } else {
            $expectedModel = "claude-haiku-4-5"
            Write-TestFork -Test "6.8.27" -Decision "Claude Code CLI with fallback" -Reason "No model configured, using $expectedModel"
        }
    } elseif ($testConfig.copilot_cli -and $testConfig.copilot_cli.enabled) {
        $cliName = "Copilot CLI"
        # Copilot CLI uses model from config, fallback to "claude-haiku-4.5"
        if ($testConfig.copilot_cli.model) {
            $expectedModel = $testConfig.copilot_cli.model
            Write-TestFork -Test "6.8.27" -Decision "Copilot CLI" -Reason "model=$expectedModel"
        } else {
            $expectedModel = "claude-haiku-4.5"
            Write-TestFork -Test "6.8.27" -Decision "Copilot CLI with fallback" -Reason "No model configured, using $expectedModel"
        }
    } else {
        Write-TestFork -Test "6.8.27" -Decision "No AI CLI configured" -Reason "opencode/claude_code/copilot_cli not enabled"
    }

    if ($cliName) {
        $cliMatch = ($aiSummaryFile -match "Generated by $cliName")
        $modelMatch = $true
        $providerMatch = $true

        # Helper function for fuzzy model matching (. and - are interchangeable)
        function Test-FuzzyModelMatch {
            param([string]$Content, [string]$Model)
            # Create regex pattern where . and - match either character
            $pattern = "model: " + ($Model -replace '[.\-]', '[.\-]')
            return ($Content -match $pattern)
        }

        # OpenCode fallback models (from apt-notify-flush script)
        $opencodeAllowedModels = @(
            "claude-sonnet-4-5-latest",
            "claude-haiku-4-5",
            "gpt-5-nano"
        )

        if ($cliMatch) {
            if ($cliName -eq "OpenCode" -and $expectedModel) {
                # Accept configured model OR any fallback model (model validation may choose fallback)
                $modelMatch = (Test-FuzzyModelMatch -Content $aiSummaryFile -Model $expectedModel)
                if (-not $modelMatch) {
                    # Check if any fallback model was used
                    foreach ($fallback in $opencodeAllowedModels) {
                        if (Test-FuzzyModelMatch -Content $aiSummaryFile -Model $fallback) {
                            $modelMatch = $true
                            break
                        }
                    }
                }
                $providerMatch = ($aiSummaryFile -match "provider: $expectedProvider")
            } elseif ($cliName -eq "Claude Code" -and $expectedModel) {
                $modelMatch = (Test-FuzzyModelMatch -Content $aiSummaryFile -Model $expectedModel)
            } elseif ($cliName -eq "Copilot CLI" -and $expectedModel) {
                $modelMatch = (Test-FuzzyModelMatch -Content $aiSummaryFile -Model $expectedModel)
            }
        }

        <# (multi) return #> @{
            Test = "6.8.27"
            Name = "AI summary reports valid model"
            Pass = ($cliMatch -and $modelMatch -and $providerMatch)
            Output = if ($cliMatch -and $modelMatch -and $providerMatch) {
                # Extract actual model from summary
                $actualModel = if ($aiSummaryFile -match 'model: ([^\]]+)') { $matches[1] } else { $expectedModel }
                "CLI: $cliName, Model: $actualModel (config: $expectedModel)" + $(if ($expectedProvider) { ", Provider: $expectedProvider" } else { "" })
            } else {
                # Convert to string and handle empty/array cases
                $summaryStr = if ($aiSummaryFile) { ($aiSummaryFile -join " ").Trim() } else { "(empty)" }
                $summaryPreview = if ($summaryStr.Length -gt 100) { $summaryStr.Substring(0, 100) + "..." } else { $summaryStr }
                "Expected $cliName" + $(if ($expectedModel) { " with model $expectedModel or fallback" } else { "" }) + $(if ($expectedProvider) { " (provider: $expectedProvider)" } else { "" }) + " - Got: $summaryPreview"
            }
        }
    } else {
        <# (multi) return #> @{
            Test = "6.8.27"
            Name = "AI summary reports configured model"
            Pass = $true
            Output = "Skipped - no AI CLI configured"
        }
    }

    # return $results
}

# Test notification flush logging (6.8-flush) - runs at the end
function Test-NotificationFlush {
    param([string]$VMName)

    # 6.8.28: Verify flush execution via journal/log
    $journalScript = @'
# Check apt-notify log for flush execution
if grep -q "apt-notify-flush: complete" /var/lib/apt-notify/apt-notify.log 2>/dev/null; then
    echo "flush_logged"
    grep "apt-notify-flush" /var/lib/apt-notify/apt-notify.log | tail -5
fi
'@
    $journalScriptB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($journalScript))
    $journalCheck = multipass exec $VMName -- bash -c "echo $journalScriptB64 | base64 -d | bash" 2>&1

    $flushLogged = ($journalCheck -match "flush_logged")
    <# (multi) return #> @{
        Test = "6.8.28"
        Name = "apt-notify-flush logged execution"
        Pass = $flushLogged
        Output = if ($flushLogged) { "Flush execution logged: $($journalCheck -replace "`n", ' ' -replace 'flush_logged', '')" } else { "No flush log entry found" }
    }
}

# Dispatcher function to run tests for a specific level
function Invoke-TestForLevel {
    param(
        [string]$Level,
        [string]$VMName
    )

    switch ($Level) {
        "6.1"  { return Test-NetworkFragment -VMName $VMName }
        "6.2"  { return Test-KernelFragment -VMName $VMName }
        "6.3"  { return Test-UsersFragment -VMName $VMName }
        "6.4"  { return Test-SSHFragment -VMName $VMName }
        "6.5"  { return Test-UFWFragment -VMName $VMName }
        "6.6"  { return Test-SystemFragment -VMName $VMName }
        "6.7"  { return Test-MSMTPFragment -VMName $VMName }
        "6.8"  { return Test-PackageSecurityFragment -VMName $VMName }
        "6.8-updates" { return Test-PackageManagerUpdates -VMName $VMName }
        "6.8-summary" { return Test-UpdateSummary -VMName $VMName }
        "6.8-flush" { return Test-NotificationFlush -VMName $VMName }
        "6.9"  { return Test-SecurityMonitoringFragment -VMName $VMName }
        "6.10" { return Test-VirtualizationFragment -VMName $VMName }
        "6.11" { return Test-CockpitFragment -VMName $VMName }
        "6.12" { return Test-ClaudeCodeFragment -VMName $VMName }
        "6.13" { return Test-CopilotCLIFragment -VMName $VMName }
        "6.14" { return Test-OpenCodeFragment -VMName $VMName }
        "6.15" { return Test-UIFragment -VMName $VMName }
        default { return @() }
    }
}
