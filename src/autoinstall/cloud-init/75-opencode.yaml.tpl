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

  # Create global config directory for admin user
  - mkdir -p /home/{{ identity.username }}/.config/opencode
  - chown -R {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.config/opencode

write_files:
  # OpenCode global configuration
  - path: /home/{{ identity.username }}/.config/opencode/opencode.json
    owner: {{ identity.username }}:{{ identity.username }}
    permissions: '0600'
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
{% endif %}
