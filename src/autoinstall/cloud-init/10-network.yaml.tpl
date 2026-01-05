hostname: {{ network.hostname }}
fqdn: {{ network.hostname }}.{{ network.dns_search }}
manage_etc_hosts: true

bootcmd:
  - |
    {{ scripts["net-setup.sh"] | indent(4) }}
