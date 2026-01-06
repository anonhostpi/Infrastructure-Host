users:
{% if testing is defined and testing %}
  - default
{% endif %}
  - name: {{ identity.username }}
    groups: [sudo, libvirt, kvm]
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

disable_root: true
ssh_pwauth: true
