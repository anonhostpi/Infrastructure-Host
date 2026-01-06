# Test Verification Functions
# Each function tests a specific fragment and returns pass/fail results

function Test-NetworkFragment {
    param([string]$VMName)

    $results = @()

    # 6.1.1: Hostname Configuration
    $hostname = multipass exec $VMName -- hostname -s 2>&1
    $results += @{
        Test = "6.1.1"
        Name = "Short hostname set"
        Pass = ($hostname -and $hostname -ne "localhost" -and $LASTEXITCODE -eq 0)
        Output = $hostname
    }

    $fqdn = multipass exec $VMName -- hostname -f 2>&1
    $results += @{
        Test = "6.1.1"
        Name = "FQDN has domain"
        Pass = ($fqdn -match "\.")
        Output = $fqdn
    }

    # 6.1.2: /etc/hosts Management
    $hosts = multipass exec $VMName -- grep "127.0.1.1" /etc/hosts 2>&1
    $results += @{
        Test = "6.1.2"
        Name = "Hostname in /etc/hosts"
        Pass = ($hosts -and $LASTEXITCODE -eq 0)
        Output = $hosts
    }

    # 6.1.3: Netplan Configuration
    $netplan = multipass exec $VMName -- bash -c "ls /etc/netplan/*.yaml 2>/dev/null" 2>&1
    $results += @{
        Test = "6.1.3"
        Name = "Netplan config exists"
        Pass = ($netplan -and $LASTEXITCODE -eq 0)
        Output = $netplan
    }

    # 6.1.4: Network Connectivity
    $ip = multipass exec $VMName -- bash -c "ip -4 addr show scope global | grep 'inet '" 2>&1
    $results += @{
        Test = "6.1.4"
        Name = "IP address assigned"
        Pass = ($ip -match "inet ")
        Output = $ip
    }

    $route = multipass exec $VMName -- bash -c "ip route | grep '^default'" 2>&1
    $results += @{
        Test = "6.1.4"
        Name = "Default gateway configured"
        Pass = ($route -match "default via")
        Output = $route
    }

    $dns = multipass exec $VMName -- host -W 2 ubuntu.com 2>&1
    $results += @{
        Test = "6.1.4"
        Name = "DNS resolution works"
        Pass = ($dns -match "has address" -or $dns -match "has IPv")
        Output = $dns
    }

    return $results
}

function Test-KernelFragment {
    param([string]$VMName)

    $results = @()

    # 6.2.1: Sysctl Security Config
    $sysctl = multipass exec $VMName -- test -f /etc/sysctl.d/99-security.conf 2>&1
    $results += @{
        Test = "6.2.1"
        Name = "Security sysctl config exists"
        Pass = ($LASTEXITCODE -eq 0)
        Output = "/etc/sysctl.d/99-security.conf"
    }

    # 6.2.2: Key security settings applied
    $rpfilter = multipass exec $VMName -- sysctl net.ipv4.conf.all.rp_filter 2>&1
    $results += @{
        Test = "6.2.2"
        Name = "Reverse path filtering enabled"
        Pass = ($rpfilter -match "= 1")
        Output = $rpfilter
    }

    $syncookies = multipass exec $VMName -- sysctl net.ipv4.tcp_syncookies 2>&1
    $results += @{
        Test = "6.2.2"
        Name = "SYN cookies enabled"
        Pass = ($syncookies -match "= 1")
        Output = $syncookies
    }

    $redirects = multipass exec $VMName -- sysctl net.ipv4.conf.all.accept_redirects 2>&1
    $results += @{
        Test = "6.2.2"
        Name = "ICMP redirects disabled"
        Pass = ($redirects -match "= 0")
        Output = $redirects
    }

    return $results
}

function Test-UsersFragment {
    param([string]$VMName)

    $results = @()
    $config = Get-CachedTestConfig
    $username = $config.identity.username

    # 6.3.1: User Exists
    $id = multipass exec $VMName -- id $username 2>&1
    $results += @{
        Test = "6.3.1"
        Name = "$username user exists"
        Pass = ($id -match "uid=" -and $LASTEXITCODE -eq 0)
        Output = $id
    }

    $shell = multipass exec $VMName -- bash -c "getent passwd $username | cut -d: -f7" 2>&1
    $results += @{
        Test = "6.3.1"
        Name = "$username shell is bash"
        Pass = ($shell -match "/bin/bash")
        Output = $shell
    }

    # 6.3.2: Group Membership
    $groups = multipass exec $VMName -- groups $username 2>&1
    $results += @{
        Test = "6.3.2"
        Name = "$username in sudo group"
        Pass = ($groups -match "\bsudo\b")
        Output = $groups
    }

    # 6.3.3: Sudo Configuration
    $sudoFile = multipass exec $VMName -- sudo test -f /etc/sudoers.d/$username 2>&1
    $results += @{
        Test = "6.3.3"
        Name = "Sudoers file exists"
        Pass = ($LASTEXITCODE -eq 0)
        Output = "/etc/sudoers.d/$username"
    }

    # 6.3.4: Root Disabled
    $root = multipass exec $VMName -- sudo passwd -S root 2>&1
    $results += @{
        Test = "6.3.4"
        Name = "Root account locked"
        Pass = ($root -match "root L" -or $root -match "root LK")
        Output = $root
    }

    return $results
}

function Test-SSHFragment {
    param([string]$VMName)

    $results = @()

    # 6.4.1: SSH Hardening Config
    $config = multipass exec $VMName -- test -f /etc/ssh/sshd_config.d/99-hardening.conf 2>&1
    $results += @{
        Test = "6.4.1"
        Name = "SSH hardening config exists"
        Pass = ($LASTEXITCODE -eq 0)
        Output = "/etc/ssh/sshd_config.d/99-hardening.conf"
    }

    # 6.4.2: Key Settings
    $permitroot = multipass exec $VMName -- bash -c "grep -r 'PermitRootLogin' /etc/ssh/sshd_config.d/" 2>&1
    $results += @{
        Test = "6.4.2"
        Name = "PermitRootLogin no"
        Pass = ($permitroot -match "PermitRootLogin no")
        Output = $permitroot
    }

    $maxauth = multipass exec $VMName -- bash -c "grep -r 'MaxAuthTries' /etc/ssh/sshd_config.d/" 2>&1
    $results += @{
        Test = "6.4.2"
        Name = "MaxAuthTries set"
        Pass = ($maxauth -match "MaxAuthTries")
        Output = $maxauth
    }

    # 6.4.3: SSH Service Running
    $sshd = multipass exec $VMName -- systemctl is-active ssh 2>&1
    $results += @{
        Test = "6.4.3"
        Name = "SSH service active"
        Pass = ($sshd -match "active")
        Output = $sshd
    }

    return $results
}

function Test-UFWFragment {
    param([string]$VMName)

    $results = @()

    # 6.5.1: UFW Installed and Enabled
    $status = multipass exec $VMName -- sudo ufw status 2>&1
    $results += @{
        Test = "6.5.1"
        Name = "UFW is active"
        Pass = ($status -match "Status: active")
        Output = $status | Select-Object -First 1
    }

    # 6.5.2: SSH Rule Exists
    $sshrule = multipass exec $VMName -- sudo ufw status 2>&1
    $results += @{
        Test = "6.5.2"
        Name = "SSH allowed in UFW"
        Pass = ($sshrule -match "22.*ALLOW")
        Output = "Port 22 rule checked"
    }

    # 6.5.3: Default Policies
    $defaults = multipass exec $VMName -- sudo ufw status verbose 2>&1
    $results += @{
        Test = "6.5.3"
        Name = "Default deny incoming"
        Pass = ($defaults -match "deny \(incoming\)")
        Output = "Default incoming policy"
    }

    return $results
}

function Test-SystemFragment {
    param([string]$VMName)

    $results = @()

    # 6.6.1: Timezone
    $tz = multipass exec $VMName -- timedatectl show --property=Timezone --value 2>&1
    $results += @{
        Test = "6.6.1"
        Name = "Timezone configured"
        Pass = ($tz -and $LASTEXITCODE -eq 0)
        Output = $tz
    }

    # 6.6.2: Locale
    $locale = multipass exec $VMName -- locale 2>&1
    $results += @{
        Test = "6.6.2"
        Name = "Locale set"
        Pass = ($locale -match "LANG=")
        Output = ($locale | Select-Object -First 1)
    }

    # 6.6.3: NTP Enabled
    $ntp = multipass exec $VMName -- timedatectl show --property=NTP --value 2>&1
    $results += @{
        Test = "6.6.3"
        Name = "NTP enabled"
        Pass = ($ntp -match "yes")
        Output = "NTP=$ntp"
    }

    return $results
}

function Test-MSMTPFragment {
    param([string]$VMName)

    $results = @()

    # 6.7.1: msmtp installed
    $msmtp = multipass exec $VMName -- which msmtp 2>&1
    $results += @{
        Test = "6.7.1"
        Name = "msmtp installed"
        Pass = ($msmtp -match "/msmtp" -and $LASTEXITCODE -eq 0)
        Output = $msmtp
    }

    # 6.7.2: msmtp config
    $config = multipass exec $VMName -- test -f /etc/msmtprc 2>&1
    $results += @{
        Test = "6.7.2"
        Name = "msmtp config exists"
        Pass = ($LASTEXITCODE -eq 0)
        Output = "/etc/msmtprc"
    }

    # 6.7.3: mail alias
    $alias = multipass exec $VMName -- test -L /usr/sbin/sendmail 2>&1
    $aliasOk = ($LASTEXITCODE -eq 0)
    if (-not $aliasOk) {
        $alias = multipass exec $VMName -- test -f /usr/sbin/sendmail 2>&1
        $aliasOk = ($LASTEXITCODE -eq 0)
    }
    $results += @{
        Test = "6.7.3"
        Name = "sendmail alias exists"
        Pass = $aliasOk
        Output = "/usr/sbin/sendmail"
    }

    return $results
}

function Test-PackageSecurityFragment {
    param([string]$VMName)

    $results = @()

    # 6.8.1: Unattended upgrades installed
    $pkg = multipass exec $VMName -- dpkg -l unattended-upgrades 2>&1
    $results += @{
        Test = "6.8.1"
        Name = "unattended-upgrades installed"
        Pass = ($pkg -match "ii.*unattended-upgrades")
        Output = "Package installed"
    }

    # 6.8.2: Config exists
    $config = multipass exec $VMName -- test -f /etc/apt/apt.conf.d/50unattended-upgrades 2>&1
    $results += @{
        Test = "6.8.2"
        Name = "Unattended upgrades config"
        Pass = ($LASTEXITCODE -eq 0)
        Output = "/etc/apt/apt.conf.d/50unattended-upgrades"
    }

    # 6.8.3: Auto-upgrades enabled
    $auto = multipass exec $VMName -- cat /etc/apt/apt.conf.d/20auto-upgrades 2>&1
    $results += @{
        Test = "6.8.3"
        Name = "Auto-upgrades configured"
        Pass = ($auto -match 'Unattended-Upgrade.*"1"')
        Output = "Auto-upgrade enabled"
    }

    # 6.8.4: Service enabled
    $svc = multipass exec $VMName -- systemctl is-enabled unattended-upgrades 2>&1
    $results += @{
        Test = "6.8.4"
        Name = "Service enabled"
        Pass = ($svc -match "enabled")
        Output = $svc
    }

    return $results
}

function Test-SecurityMonitoringFragment {
    param([string]$VMName)

    $results = @()

    # 6.9.1: fail2ban installed
    $f2b = multipass exec $VMName -- which fail2ban-client 2>&1
    $results += @{
        Test = "6.9.1"
        Name = "fail2ban installed"
        Pass = ($f2b -match "fail2ban" -and $LASTEXITCODE -eq 0)
        Output = $f2b
    }

    # 6.9.2: fail2ban running
    $status = multipass exec $VMName -- sudo systemctl is-active fail2ban 2>&1
    $results += @{
        Test = "6.9.2"
        Name = "fail2ban service active"
        Pass = ($status -match "active")
        Output = $status
    }

    # 6.9.3: SSH jail enabled
    $jails = multipass exec $VMName -- sudo fail2ban-client status 2>&1
    $results += @{
        Test = "6.9.3"
        Name = "SSH jail configured"
        Pass = ($jails -match "sshd")
        Output = "sshd jail"
    }

    return $results
}

function Test-VirtualizationFragment {
    param([string]$VMName)

    $results = @()

    # 6.10.1: libvirt installed
    $libvirt = multipass exec $VMName -- which virsh 2>&1
    $results += @{
        Test = "6.10.1"
        Name = "libvirt installed"
        Pass = ($libvirt -match "virsh" -and $LASTEXITCODE -eq 0)
        Output = $libvirt
    }

    # 6.10.2: libvirtd running
    $svc = multipass exec $VMName -- systemctl is-active libvirtd 2>&1
    $results += @{
        Test = "6.10.2"
        Name = "libvirtd service active"
        Pass = ($svc -match "active")
        Output = $svc
    }

    # 6.10.3: QEMU/KVM available
    $qemu = multipass exec $VMName -- which qemu-system-x86_64 2>&1
    $results += @{
        Test = "6.10.3"
        Name = "QEMU installed"
        Pass = ($qemu -match "qemu" -and $LASTEXITCODE -eq 0)
        Output = $qemu
    }

    # 6.10.4: Default network
    $net = multipass exec $VMName -- sudo virsh net-list --all 2>&1
    $results += @{
        Test = "6.10.4"
        Name = "Default network exists"
        Pass = ($net -match "default")
        Output = "virsh net-list"
    }

    return $results
}

function Test-CockpitFragment {
    param([string]$VMName)

    $results = @()

    # 6.11.1: Cockpit installed
    $cockpit = multipass exec $VMName -- which cockpit-bridge 2>&1
    $results += @{
        Test = "6.11.1"
        Name = "Cockpit installed"
        Pass = ($cockpit -match "cockpit" -and $LASTEXITCODE -eq 0)
        Output = $cockpit
    }

    # 6.11.2: Cockpit socket enabled
    $socket = multipass exec $VMName -- systemctl is-enabled cockpit.socket 2>&1
    $results += @{
        Test = "6.11.2"
        Name = "Cockpit socket enabled"
        Pass = ($socket -match "enabled")
        Output = $socket
    }

    # 6.11.3: Cockpit machines plugin
    $machines = multipass exec $VMName -- dpkg -l cockpit-machines 2>&1
    $results += @{
        Test = "6.11.3"
        Name = "cockpit-machines installed"
        Pass = ($machines -match "ii.*cockpit-machines")
        Output = "Package installed"
    }

    return $results
}

function Test-OpenCodeFragment {
    param([string]$VMName)

    $results = @()

    # 6.12.1: Node.js installed
    $node = multipass exec $VMName -- which node 2>&1
    $results += @{
        Test = "6.12.1"
        Name = "Node.js installed"
        Pass = ($node -match "node" -and $LASTEXITCODE -eq 0)
        Output = $node
    }

    # 6.12.2: npm installed
    $npm = multipass exec $VMName -- which npm 2>&1
    $results += @{
        Test = "6.12.2"
        Name = "npm installed"
        Pass = ($npm -match "npm" -and $LASTEXITCODE -eq 0)
        Output = $npm
    }

    # 6.12.3: OpenCode setup
    $opencode = multipass exec $VMName -- which opencode 2>&1
    $results += @{
        Test = "6.12.3"
        Name = "OpenCode CLI installed"
        Pass = ($opencode -match "opencode" -and $LASTEXITCODE -eq 0)
        Output = $opencode
    }

    return $results
}

function Test-UIFragment {
    param([string]$VMName)

    $results = @()

    # 6.13.1: MOTD configured
    $motd = multipass exec $VMName -- test -d /etc/update-motd.d 2>&1
    $results += @{
        Test = "6.13.1"
        Name = "MOTD directory exists"
        Pass = ($LASTEXITCODE -eq 0)
        Output = "/etc/update-motd.d"
    }

    # 6.13.2: Custom MOTD scripts
    $scripts = multipass exec $VMName -- bash -c "ls /etc/update-motd.d/ | wc -l" 2>&1
    $results += @{
        Test = "6.13.2"
        Name = "MOTD scripts present"
        Pass = ([int]$scripts -gt 0)
        Output = "$scripts scripts"
    }

    return $results
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
        "6.9"  { return Test-SecurityMonitoringFragment -VMName $VMName }
        "6.10" { return Test-VirtualizationFragment -VMName $VMName }
        "6.11" { return Test-CockpitFragment -VMName $VMName }
        "6.12" { return Test-OpenCodeFragment -VMName $VMName }
        "6.13" { return Test-UIFragment -VMName $VMName }
        default { return @() }
    }
}
