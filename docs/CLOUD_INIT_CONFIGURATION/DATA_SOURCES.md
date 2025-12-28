# 5.1 Cloud-init Data Sources

For bare-metal deployments, use the NoCloud data source.

## Option 1: Separate Cloud-init ISO (Recommended)

- Create a second ISO containing only cloud-init configuration
- Attach during first boot
- Easy to update without modifying installation media

## Option 2: Embed in Autoinstall

- Include cloud-init directives in autoinstall user-data
- Applied after installation completes
- Self-contained but harder to update

## Option 3: Local Filesystem

- Place cloud-init files in `/var/lib/cloud/seed/nocloud-net/`
- Useful for manual installation followed by cloud-init
- Requires SSH/console access to the system

## Data Source Priority

Cloud-init checks for configuration in this order:
1. NoCloud (ISO or seed directory)
2. ConfigDrive
3. OpenStack
4. AWS EC2
5. Azure
6. GCE

For bare-metal, NoCloud is the appropriate choice.

## NoCloud Configuration Files

| File | Purpose |
|------|---------|
| `user-data` | Main configuration (required) |
| `meta-data` | Instance metadata (required, can be minimal) |
| `network-config` | Network configuration (optional) |
| `vendor-data` | Vendor-specific configuration (optional) |
