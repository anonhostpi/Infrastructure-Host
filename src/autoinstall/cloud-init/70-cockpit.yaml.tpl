{% if cockpit.enabled | default(true) %}
packages:
  - cockpit
{% if cockpit.packages is defined %}
{% for pkg in cockpit.packages | default(['cockpit-machines']) %}
  - {{ pkg }}
{% endfor %}
{% endif %}

write_files:
  - path: /etc/cockpit/cockpit.conf
    permissions: '644'
    content: |
      [WebService]
      AllowUnencrypted = {{ 'true' if not cockpit.require_https | default(true) else 'false' }}
{% if cockpit.idle_timeout | default(0) > 0 %}
      IdleTimeout = {{ cockpit.idle_timeout }}
{% endif %}
{% if cockpit.origins is defined and cockpit.origins %}
      Origins = {{ cockpit.origins | join(' ') }}
{% endif %}

  - path: /etc/systemd/system/cockpit.socket.d/listen.conf
    permissions: '644'
    content: |
      [Socket]
      ListenStream=
      ListenStream={{ cockpit.listen_address | default('127.0.0.1') }}:{{ cockpit.listen_port | default(443) }}

runcmd:
  - systemctl daemon-reload
  - systemctl enable cockpit.socket
  - systemctl start cockpit.socket
{% endif %}
