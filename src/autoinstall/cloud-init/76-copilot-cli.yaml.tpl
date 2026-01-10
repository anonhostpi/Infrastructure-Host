{% if copilot_cli.enabled | default(false) %}
runcmd:
  # Install Node.js LTS via apt (NodeSource repo for unattended-upgrades support)
  - command -v node || (curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && apt-get install -y nodejs)
  # Install GitHub Copilot CLI globally via npm (updated by unattended-upgrades Post-Invoke hook)
  - npm install -g @githubnext/github-copilot-cli

  # Create config directory for admin user
  - mkdir -p /home/{{ identity.username }}/.copilot
  - chown -R {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.copilot

{% if copilot_cli.auth.gh_token is defined %}
  # Set GH_TOKEN environment variable system-wide (fallback auth method)
  - echo 'GH_TOKEN={{ copilot_cli.auth.gh_token }}' >> /etc/environment
{% endif %}

write_files:
  # Copilot CLI configuration with OAuth token
  - path: /home/{{ identity.username }}/.copilot/config.json
    owner: {{ identity.username }}:{{ identity.username }}
    permissions: '600'
    content: |
      {
        "$schema": "https://copilot.github.com/config.json"
        {%- if copilot_cli.settings is defined %}
        {%- if copilot_cli.settings.allow_all_paths is defined %},
        "allowAllPaths": {{ 'true' if copilot_cli.settings.allow_all_paths else 'false' }}
        {%- endif %}
        {%- if copilot_cli.settings.allow_all_urls is defined %},
        "allowAllUrls": {{ 'true' if copilot_cli.settings.allow_all_urls else 'false' }}
        {%- endif %}
        {%- endif %}
        {%- if copilot_cli.auth.oauth is defined %},
        "copilot_tokens": {
          "https://github.com:{{ copilot_cli.auth.oauth.github_username }}": "{{ copilot_cli.auth.oauth.oauth_token }}"
        },
        "logged_in_users": [
          {
            "host": "https://github.com",
            "login": "{{ copilot_cli.auth.oauth.github_username }}"
          }
        ],
        "last_logged_in_user": {
          "host": "https://github.com",
          "login": "{{ copilot_cli.auth.oauth.github_username }}"
        }
        {%- endif %}
      }

{% if copilot_cli.auth.gh_token is defined %}
  # Store GH_TOKEN in user's bashrc for interactive sessions (fallback)
  - path: /home/{{ identity.username }}/.bashrc.d/copilot-cli.sh
    owner: {{ identity.username }}:{{ identity.username }}
    permissions: '600'
    content: |
      # GitHub Copilot CLI token (fallback)
      export GH_TOKEN="{{ copilot_cli.auth.gh_token }}"
{% endif %}
{% endif %}
