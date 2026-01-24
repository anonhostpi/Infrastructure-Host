#!/bin/bash
# Auto-generated user setup script for cloud-init
# Runs on first boot via bootcmd
# Base64 encoded to avoid YAML multiline string parsing issues

# Skip if user already exists (idempotent)
if id -u {{ identity.username }} >/dev/null 2>&1; then
  echo "user-setup: User {{ identity.username }} already exists, skipping"
  exit 0
fi

echo "user-setup: Creating user {{ identity.username }}"

# Create user - only add to sudo group here; virtualization groups added by 60-virtualization
# If group already exists (Ubuntu has 'admin' group by default), use -g to join it
# Otherwise useradd creates a user private group automatically
if getent group {{ identity.username }} >/dev/null 2>&1; then
  echo "user-setup: Group {{ identity.username }} exists, using it as primary group"
  useradd -m -s /bin/bash -g {{ identity.username }} -G sudo {{ identity.username }}
else
  useradd -m -s /bin/bash -G sudo {{ identity.username }}
fi

# Verify user was created
if ! id -u {{ identity.username }} >/dev/null 2>&1; then
  echo "user-setup: ERROR - Failed to create user {{ identity.username }}"
  exit 1
fi

# Set password (hashed)
echo '{{ identity.username }}:{{ identity.password | sha512_hash }}' | chpasswd -e

# Configure passwordless sudo
echo '{{ identity.username }} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/{{ identity.username }}
chmod 440 /etc/sudoers.d/{{ identity.username }}

{% if identity.ssh_authorized_keys is defined and identity.ssh_authorized_keys %}
# Configure SSH authorized keys
echo "user-setup: Configuring SSH keys for {{ identity.username }}"
mkdir -p /home/{{ identity.username }}/.ssh
chmod 700 /home/{{ identity.username }}/.ssh
: > /home/{{ identity.username }}/.ssh/authorized_keys
{% for key in identity.ssh_authorized_keys %}
echo '{{ key }}' >> /home/{{ identity.username }}/.ssh/authorized_keys
{% endfor %}
chmod 600 /home/{{ identity.username }}/.ssh/authorized_keys
chown -R {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.ssh
{% endif %}

# Lock root account
passwd -l root

echo "user-setup: User {{ identity.username }} created successfully"
exit 0
