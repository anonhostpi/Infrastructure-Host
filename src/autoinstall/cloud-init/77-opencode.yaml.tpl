{% if opencode.enabled | default(false) %}
runcmd:
  # Install Node.js LTS via apt (NodeSource repo for unattended-upgrades support)
  - command -v node || (curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && apt-get install -y nodejs)
  # Install opencode globally via npm (updated by unattended-upgrades Post-Invoke hook)
  - npm install -g opencode-ai

  # Create config directories for admin user
  - mkdir -p /home/{{ identity.username }}/.config/opencode
  - mkdir -p /home/{{ identity.username }}/.local/share/opencode

  # Write OpenCode config file (using heredoc to ensure order after mkdir)
  - |
    cat > /home/{{ identity.username }}/.config/opencode/opencode.json << 'OPENCODE_CONFIG_EOF'
    {
      "$schema": "https://opencode.ai/config.json",
      "model": "{{ opencode.model | default('anthropic/claude-sonnet-4-5') }}",
      "theme": "{{ opencode.theme | default('dark') }}",
      "autoupdate": {{ opencode.autoupdate | default(false) | tojson }}
      {%- if opencode.providers is defined %},
      "provider": {
        {%- for provider_id, provider in opencode.providers.items() %}
        "{{ provider_id }}": {
          {%- if provider.name is defined %}
          "name": "{{ provider.name }}",
          {%- endif %}
          {%- if provider_id == 'ollama' or provider.name is defined %}
          "npm": "@ai-sdk/openai-compatible",
          {%- endif %}
          "options": {
            {%- if provider.base_url is defined %}
            "baseURL": "{{ provider.base_url }}"
            {%- endif %}
            {%- if provider.api_key is defined %}
            {%- if provider.base_url is defined %},{% endif %}
            "apiKey": "{{ provider.api_key }}"
            {%- endif %}
          }
          {%- if provider.models is defined %},
          "models": {
            {%- for model_id, model in provider.models.items() %}
            "{{ model_id }}": {
              "name": "{{ model.name }}"
              {%- if model.context is defined or model.output is defined %},
              "limit": {
                {%- if model.context is defined %}
                "context": {{ model.context }}
                {%- endif %}
                {%- if model.output is defined %}
                {%- if model.context is defined %},{% endif %}
                "output": {{ model.output }}
                {%- endif %}
              }
              {%- endif %}
            }{% if not loop.last %},{% endif %}
            {%- endfor %}
          }
          {%- endif %}
        }{% if not loop.last %},{% endif %}
        {%- endfor %}
      }
      {%- endif %}
    }
    OPENCODE_CONFIG_EOF
  - chmod 600 /home/{{ identity.username }}/.config/opencode/opencode.json

{% if opencode.auth is defined %}
  # Write OpenCode auth.json (derived from Claude Code and Copilot CLI credentials)
  - |
    cat > /home/{{ identity.username }}/.local/share/opencode/auth.json << 'OPENCODE_AUTH_EOF'
    {
      {%- set has_anthropic = opencode.auth.anthropic is defined %}
      {%- set has_copilot = opencode.auth.github_copilot is defined %}
      {%- if has_anthropic %}
      "anthropic": {
        "type": "oauth",
        "access": "{{ opencode.auth.anthropic.access_token }}",
        "refresh": "{{ opencode.auth.anthropic.refresh_token }}"
        {%- if opencode.auth.anthropic.expires_at is defined %},
        "expires": {{ opencode.auth.anthropic.expires_at }}
        {%- endif %}
      }
      {%- endif %}
      {%- if has_anthropic and has_copilot %},{% endif %}
      {%- if has_copilot %}
      "github-copilot": {
        "type": "oauth",
        "refresh": "{{ opencode.auth.github_copilot.oauth_token }}"
        {%- if opencode.auth.github_copilot.access_token is defined %},
        "access": "{{ opencode.auth.github_copilot.access_token }}"
        {%- endif %}
        {%- if opencode.auth.github_copilot.expires_at is defined %},
        "expires": {{ opencode.auth.github_copilot.expires_at }}
        {%- endif %}
      }
      {%- endif %}
    }
    OPENCODE_AUTH_EOF
  - chmod 600 /home/{{ identity.username }}/.local/share/opencode/auth.json
{% endif %}

  # Set ownership after all files are written
  - chown -R {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.config/opencode
  - chown -R {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.local/share/opencode
{% endif %}
