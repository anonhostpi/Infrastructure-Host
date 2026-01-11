{% if claude_code.enabled | default(false) %}
runcmd:
  # Install Node.js LTS via apt (NodeSource repo for unattended-upgrades support)
  - command -v node || (curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && apt-get install -y nodejs)
  # Install Claude Code globally via npm (updated by unattended-upgrades Post-Invoke hook)
  - npm install -g @anthropic-ai/claude-code

  # Create config directory for admin user
  - mkdir -p /home/{{ identity.username }}/.claude

  # Write Claude Code settings file
  - |
    cat > /home/{{ identity.username }}/.claude/settings.json << 'CLAUDE_SETTINGS_EOF'
    {
      "model": "{{ claude_code.model | default('claude-sonnet-4-5-20250514') }}"
      {%- if claude_code.settings is defined %}
      {%- if claude_code.settings.auto_update is defined %},
      "autoUpdater": {
        "disabled": {{ 'true' if not claude_code.settings.auto_update else 'false' }}
      }
      {%- endif %}
      {%- if claude_code.settings.permissions is defined %},
      "permissions": {{ claude_code.settings.permissions | tojson }}
      {%- endif %}
      {%- endif %}
    }
    CLAUDE_SETTINGS_EOF
  - chmod 600 /home/{{ identity.username }}/.claude/settings.json

{% if claude_code.auth.oauth is defined %}
  # Write OAuth credentials from authenticated Claude Code instance
  - |
    cat > /home/{{ identity.username }}/.claude/.credentials.json << 'CLAUDE_CREDS_EOF'
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
    CLAUDE_CREDS_EOF
  - chmod 600 /home/{{ identity.username }}/.claude/.credentials.json

  # Write state file to skip onboarding
  - |
    cat > /home/{{ identity.username }}/.claude.json << 'CLAUDE_STATE_EOF'
    {
      "hasCompletedOnboarding": true,
      "lastOnboardingVersion": "{{ claude_code.auth.oauth.onboarding_version | default('2.0.55') }}",
      "autoUpdates": {{ 'true' if claude_code.settings.auto_update | default(false) else 'false' }}
    }
    CLAUDE_STATE_EOF
  - chmod 600 /home/{{ identity.username }}/.claude.json
  - chown {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.claude.json
{% endif %}

{% if claude_code.auth.api_key is defined %}
  # Set ANTHROPIC_API_KEY environment variable system-wide
  - echo 'ANTHROPIC_API_KEY={{ claude_code.auth.api_key }}' >> /etc/environment

  # Store API key in user's bashrc for interactive sessions
  - mkdir -p /home/{{ identity.username }}/.bashrc.d
  - |
    cat > /home/{{ identity.username }}/.bashrc.d/claude-code.sh << 'CLAUDE_BASHRC_EOF'
    # Claude Code API key
    export ANTHROPIC_API_KEY="{{ claude_code.auth.api_key }}"
    CLAUDE_BASHRC_EOF
  - chmod 600 /home/{{ identity.username }}/.bashrc.d/claude-code.sh
  - chown {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.bashrc.d/claude-code.sh
{% endif %}

  # Set ownership of .claude directory after all files are written
  - chown -R {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.claude
{% endif %}
