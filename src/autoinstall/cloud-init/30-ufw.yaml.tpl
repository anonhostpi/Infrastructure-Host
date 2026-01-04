packages:
  - ufw

runcmd:
  - ufw default deny incoming
  - ufw default allow outgoing
  - ufw limit ssh
  - ufw logging medium
  - ufw --force enable
