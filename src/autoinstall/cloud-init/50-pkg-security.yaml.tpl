package_update: true
package_upgrade: true

packages:
  - unattended-upgrades
  - apt-listchanges

write_files:
  - path: /etc/apt/apt.conf.d/50unattended-upgrades
    permissions: '0644'
    content: |
      Unattended-Upgrade::Allowed-Origins {
          "${distro_id}:${distro_codename}-security";
          "${distro_id}ESMApps:${distro_codename}-apps-security";
          "${distro_id}ESM:${distro_codename}-infra-security";
      };

      Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
      Unattended-Upgrade::Remove-Unused-Dependencies "true";

      // Disable auto-reboot for KVM host (VMs may be running)
      Unattended-Upgrade::Automatic-Reboot "false";

      // Email notification (requires msmtp - see 6.7)
      Unattended-Upgrade::Mail "root";
      Unattended-Upgrade::MailReport "on-change";

      Unattended-Upgrade::SyslogEnable "true";

  - path: /etc/apt/apt.conf.d/20auto-upgrades
    permissions: '0644'
    content: |
      APT::Periodic::Update-Package-Lists "1";
      APT::Periodic::Unattended-Upgrade "1";
      APT::Periodic::AutocleanInterval "7";
