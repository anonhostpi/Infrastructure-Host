users:
  - name: {{ identity.username }}
    groups: [sudo, adm, libvirt, kvm]
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    passwd: {{ identity.password | sha512_hash }}
{% if identity.ssh_authorized_keys is defined and identity.ssh_authorized_keys %}
    ssh_authorized_keys:
{% for key in identity.ssh_authorized_keys %}
      - {{ key }}
{% endfor %}
{% endif %}
