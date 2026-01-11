hostname: {{ network.hostname }}
fqdn: {{ network.hostname }}.{{ network.dns_search }}
manage_etc_hosts: true

bootcmd:
  # Wrap in subshell so exit doesn't terminate the combined bootcmd script
  - |
    (
    {{ scripts["net-setup.sh"] | indent(4) }}
    )
