{% if claude_code.enabled | default(false) %}
runcmd:
  # Install Node.js LTS via apt (NodeSource repo for unattended-upgrades support)
  - command -v node || (curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && apt-get install -y nodejs)
  # Install Claude Code globally via npm (updated by unattended-upgrades Post-Invoke hook)
  - npm install -g @anthropic-ai/claude-code

  # Create config directory for admin user
  - mkdir -p /home/{{ identity.username }}/.claude
  - chown -R {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.claude

{% if claude_code.auth.api_key is defined %}
  # Set ANTHROPIC_API_KEY environment variable system-wide
  - echo 'ANTHROPIC_API_KEY={{ claude_code.auth.api_key }}' >> /etc/environment
{% endif %}

write_files:
  # Claude Code settings configuration
  - path: /home/{{ identity.username }}/.claude/settings.json
    owner: {{ identity.username }}:{{ identity.username }}
    permissions: '600'
    content: |
      {
        "model": "{{ claude_code.model | default('claude-sonnet-4-5-20250514') }}"
        {%- if claude_code.settings is defined %}
        {%- if claude_code.settings.auto_update is defined %},
        "autoUpdater": {
          "disabled": {{ 'true' if not claude_code.settings.auto_update else 'false' }}
        }
        {%- endif %}
        {%- if claude_code.settings.permissions is defined %},
        "permissions": {{ claude_code.settings.permissions | to_yaml | trim }}
        {%- endif %}
        {%- endif %}
      }

{% if claude_code.auth.oauth is defined %}
  # OAuth credentials from authenticated Claude Code instance
  - path: /home/{{ identity.username }}/.claude/.credentials.json
    owner: {{ identity.username }}:{{ identity.username }}
    permissions: '600'
    content: |
      {
        "claudeAiOauth": {
          "accessToken": "{{ claude_code.auth.oauth.access_token }}",
          "refreshToken": "{{ claude_code.auth.oauth.refresh_token }}"
          {%- if claude_code.auth.oauth.expires_at is defined %},
          "expiresAt": {{ claude_code.auth.oauth.expires_at }}
          {%- endif %}
          {%- if claude_code.auth.oauth.scopes is defined %},
          "scopes": {{ claude_code.auth.oauth.scopes | tojson }}
          {%- else %},
          "scopes": ["user:inference", "user:profile", "user:sessions:claude_code"]
          {%- endif %}
          {%- if claude_code.auth.oauth.subscription_type is defined %},
          "subscriptionType": "{{ claude_code.auth.oauth.subscription_type }}"
          {%- endif %}
        }
      }

  # State file to skip onboarding
  - path: /home/{{ identity.username }}/.claude.json
    owner: {{ identity.username }}:{{ identity.username }}
    permissions: '600'
    content: |
      {
        "hasCompletedOnboarding": true,
        "lastOnboardingVersion": "{{ claude_code.auth.oauth.onboarding_version | default('2.0.55') }}",
        "autoUpdates": {{ 'true' if claude_code.settings.auto_update | default(false) else 'false' }}
      }
{% endif %}

{% if claude_code.auth.api_key is defined %}
  # Store API key in user's bashrc for interactive sessions
  - path: /home/{{ identity.username }}/.bashrc.d/claude-code.sh
    owner: {{ identity.username }}:{{ identity.username }}
    permissions: '600'
    content: |
      # Claude Code API key
      export ANTHROPIC_API_KEY="{{ claude_code.auth.api_key }}"
{% endif %}
{% endif %}
