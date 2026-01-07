# Package upgrade - runs last after all other configuration
# Separated from 50-pkg-security to ensure all packages are installed first,
# then upgraded together at the end.

runcmd:
  # Full system upgrade (runs after all cloud-init packages are installed)
  - |
    echo "=== Starting full system upgrade ==="
    export DEBIAN_FRONTEND=noninteractive

    # Update package lists
    apt-get update -q

    # Perform upgrade, capturing what would be held back
    HELD_BACK=$(apt-get -s upgrade 2>/dev/null | grep "kept back" | sed 's/.*: //' || true)

    # Standard upgrade (won't remove packages or install new deps)
    apt-get upgrade -y -q \
      -o Dpkg::Options::="--force-confdef" \
      -o Dpkg::Options::="--force-confold"

    # Log held-back packages for visibility
    if [ -n "$HELD_BACK" ]; then
      echo "=== Packages held back (run 'apt full-upgrade' to install): ==="
      echo "$HELD_BACK"
      logger -t cloud-init "Packages held back during upgrade: $HELD_BACK"
    fi

    # Autoremove unused packages
    apt-get autoremove -y -q

    # Clean up apt cache
    apt-get clean

    echo "=== System upgrade complete ==="
