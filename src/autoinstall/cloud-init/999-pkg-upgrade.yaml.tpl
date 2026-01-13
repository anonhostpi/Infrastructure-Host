# Package upgrade - runs last after all other configuration
# Triggers unattended-upgrades and pkg-managers-update.service so that:
# 1. All packages get upgraded through the proper channels
# 2. Notifications get sent out via apt-notify system

runcmd:
  # Full system upgrade via unattended-upgrades and pkg-managers-update
  - |
    echo "=== Starting full system upgrade via unattended-upgrades ==="
    export DEBIAN_FRONTEND=noninteractive

    # Update package lists first
    apt-get update -q

    # Trigger unattended-upgrades to handle apt packages
    # This will use the configured notification system (apt-notify)
    echo "Running unattended-upgrades..."
    unattended-upgrade -v

    # Trigger pkg-managers-update.service to handle snap, brew, pip, npm, deno
    # This will queue changes to apt-notify for unified notification
    echo "Running pkg-managers-update.service..."
    systemctl start pkg-managers-update.service || true

    # Clean up apt cache
    apt-get clean

    echo "=== System upgrade complete ==="
