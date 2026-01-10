{% if opencode.enabled | default(false) %}
runcmd:
{% if opencode.install_method | default('npm') == 'npm' %}
  # Install Node.js via NodeSource (LTS)
  - curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
  - apt-get install -y nodejs
  # Install opencode globally
  - npm install -g opencode-ai
{% elif opencode.install_method == 'script' %}
  # Install via official script
  - curl -fsSL https://opencode.ai/install | bash
{% endif %}

  # Create config directories for admin user
  - mkdir -p /home/{{ identity.username }}/.config/opencode
  - mkdir -p /home/{{ identity.username }}/.local/share/opencode
  - chown -R {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.config/opencode
  - chown -R {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.local/share/opencode

write_files:
  # OpenCode global configuration
  - path: /home/{{ identity.username }}/.config/opencode/opencode.json
    owner: {{ identity.username }}:{{ identity.username }}
    permissions: '600'
    content: |
      {
        "$schema": "https://opencode.ai/config.json",
        "model": "{{ opencode.model | default('anthropic/claude-sonnet-4-5') }}",
        "theme": "{{ opencode.theme | default('dark') }}",
        "autoupdate": "notify"
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

{% if opencode.auth is defined %}
  # OpenCode auth.json - derived from Claude Code and Copilot CLI credentials
  # See: https://opencode.ai/docs/auth
  - path: /home/{{ identity.username }}/.local/share/opencode/auth.json
    owner: {{ identity.username }}:{{ identity.username }}
    permissions: '600'
    content: |
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
{% endif %}
{% endif %}
