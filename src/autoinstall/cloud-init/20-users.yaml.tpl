bootcmd:
  # Create admin user in bootcmd (runs early, before write_files with defer:true)
  # This ensures the user exists when deferred write_files need to set ownership
  # Wrapped in conditional to only run once (bootcmd runs on every boot)
  - |
    if ! id -u {{ identity.username }} >/dev/null 2>&1; then
      # Create user - only add to sudo group here; virtualization groups added by 60-virtualization
      useradd -m -s /bin/bash -N -G sudo {{ identity.username }}
      echo '{{ identity.username }}:{{ identity.password | sha512_hash }}' | chpasswd -e
      echo '{{ identity.username }} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/{{ identity.username }}
      chmod 440 /etc/sudoers.d/{{ identity.username }}
{% if identity.ssh_authorized_keys is defined and identity.ssh_authorized_keys %}
      mkdir -p /home/{{ identity.username }}/.ssh
      chmod 700 /home/{{ identity.username }}/.ssh
      cat > /home/{{ identity.username }}/.ssh/authorized_keys << 'SSH_KEYS_EOF'
{% for key in identity.ssh_authorized_keys %}
      {{ key }}
{% endfor %}
      SSH_KEYS_EOF
      chmod 600 /home/{{ identity.username }}/.ssh/authorized_keys
      chown -R {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.ssh
{% endif %}
      # Lock root account
      passwd -l root
    fi

ssh_pwauth: true
