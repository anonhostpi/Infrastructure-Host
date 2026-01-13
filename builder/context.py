"""BuildContext loads configuration files and exposes them to templates."""

import json
import os
import re
from pathlib import Path
import yaml

from .composer import deep_merge


class BuildContext:
    """
    Loads all *.config.yaml files from src/config/ directory.
    Each file becomes a top-level key (filename before .config.yaml).

    Auto-unwrap: If a config has only one top-level key AND that key
    matches the filename, unwrap it. e.g., identity.config.yaml with
    'identity:' unwraps, but network.config.yaml with 'host:' does not.

    Testing mode: When testing.config.yaml exists and has testing: true,
    nested config keys (like network:) override their main config counterparts.

    Environment variables override config values after loading.
    """

    def __init__(self, configs_dir='src/config', env_prefix='AUTOINSTALL_'):
        self._data = {}
        self._paths = {}  # Maps normalized env name -> (path, original_path_str)

        # Load all config files
        configs_path = Path(configs_dir)
        if configs_path.exists():
            for filepath in configs_path.glob('*.config.yaml'):
                key = filepath.name.replace('.config.yaml', '')
                with open(filepath) as f:
                    content = yaml.safe_load(f)
                    # Auto-unwrap only if single key matches filename
                    if isinstance(content, dict) and len(content) == 1:
                        only_key = next(iter(content.keys()))
                        if only_key == key:
                            content = content[only_key]
                    self._data[key] = content

        # Apply testing config overrides (if testing: true)
        self._apply_testing_overrides()

        # Load OAuth credentials from host files as fallback
        self._apply_credential_fallbacks()

        # Build path index for env var matching
        self._index_paths(self._data, [])

        # Apply environment variable overrides
        self._apply_env_overrides(env_prefix)

    def _apply_testing_overrides(self):
        """Apply nested config overrides from testing.config.yaml when testing: true."""
        testing_config = self._data.get('testing', {})
        if not isinstance(testing_config, dict):
            return

        # Check if testing mode is enabled
        if not testing_config.get('testing', False):
            return

        # Apply nested configs as overrides to their main counterparts
        for key, value in testing_config.items():
            if key == 'testing':
                # Skip the testing flag itself
                continue
            if key in self._data and isinstance(value, dict):
                # Deep merge testing override into main config
                self._data[key] = deep_merge(self._data[key], value)
            elif isinstance(value, dict):
                # New config section from testing
                self._data[key] = value

    def _apply_credential_fallbacks(self):
        """Load OAuth credentials from host files as fallback for AI CLI configs.

        This allows the builder to automatically use credentials from authenticated
        CLI instances on the build machine, without requiring explicit config.

        Credential file locations:
        - Claude Code: ~/.claude/.credentials.json, ~/.claude.json
        - Copilot CLI: ~/.copilot/config.json (copilot_tokens key)

        OpenCode auth is derived from Claude Code and Copilot CLI credentials
        (not loaded from host directly).
        """
        home = Path.home()

        # Claude Code OAuth fallback
        self._apply_claude_code_fallback(home)

        # Copilot CLI OAuth fallback
        self._apply_copilot_cli_fallback(home)

        # Derive OpenCode auth from Claude Code and Copilot CLI
        self._derive_opencode_auth()

        # Derive OpenCode providers/models from Claude Code and Copilot CLI
        self._derive_opencode_providers()

    def _apply_claude_code_fallback(self, home):
        """Load Claude Code OAuth credentials as fallback."""
        creds_file = home / '.claude' / '.credentials.json'
        state_file = home / '.claude.json'

        if not creds_file.exists() or not state_file.exists():
            return

        # Check if claude_code config exists and has auth.oauth already set
        claude_config = self._data.get('claude_code', {})
        if not isinstance(claude_config, dict):
            return

        auth = claude_config.get('auth', {})
        if auth.get('oauth') or auth.get('api_key'):
            # Auth already configured, don't override
            return

        try:
            with open(creds_file) as f:
                creds = json.load(f)
            with open(state_file) as f:
                state = json.load(f)

            oauth_data = creds.get('claudeAiOauth', {})
            if not oauth_data.get('accessToken'):
                return

            # Build OAuth config from credential files
            oauth_config = {
                'access_token': oauth_data.get('accessToken'),
                'refresh_token': oauth_data.get('refreshToken'),
            }
            if oauth_data.get('expiresAt'):
                oauth_config['expires_at'] = oauth_data['expiresAt']
            if oauth_data.get('subscriptionType'):
                oauth_config['subscription_type'] = oauth_data['subscriptionType']
            if state.get('lastOnboardingVersion'):
                oauth_config['onboarding_version'] = state['lastOnboardingVersion']

            # Apply as fallback
            if 'claude_code' not in self._data:
                self._data['claude_code'] = {}
            if 'auth' not in self._data['claude_code']:
                self._data['claude_code']['auth'] = {}
            self._data['claude_code']['auth']['oauth'] = oauth_config

        except (json.JSONDecodeError, KeyError, IOError):
            # Silently skip if credential files are malformed
            pass

    def _apply_copilot_cli_fallback(self, home):
        """Load Copilot CLI OAuth credentials as fallback from config.json."""
        config_file = home / '.copilot' / 'config.json'

        if not config_file.exists():
            return

        # Check if copilot_cli config exists and has auth already set
        copilot_config = self._data.get('copilot_cli', {})
        if not isinstance(copilot_config, dict):
            return

        auth = copilot_config.get('auth', {})
        if auth.get('oauth') or auth.get('gh_token'):
            # Auth already configured, don't override
            return

        try:
            with open(config_file) as f:
                config = json.load(f)

            copilot_tokens = config.get('copilot_tokens', {})
            if not copilot_tokens:
                return

            # Get the first token (format: "https://github.com:username": "gho_xxx")
            account, token = next(iter(copilot_tokens.items()))
            if not token:
                return

            # Parse username from account (format: "https://github.com:username")
            parts = account.split(':')
            if len(parts) < 2:
                return
            username = parts[-1]

            # Build OAuth config from copilot config.json
            oauth_config = {
                'github_username': username,
                'oauth_token': token,
            }

            # Apply as fallback
            if 'copilot_cli' not in self._data:
                self._data['copilot_cli'] = {}
            if 'auth' not in self._data['copilot_cli']:
                self._data['copilot_cli']['auth'] = {}
            self._data['copilot_cli']['auth']['oauth'] = oauth_config

        except (json.JSONDecodeError, KeyError, IOError, StopIteration):
            # Silently skip if credential files are malformed
            pass

    def _derive_opencode_auth(self):
        """Derive OpenCode auth.json credentials from Claude Code and Copilot CLI.

        OpenCode uses auth.json at ~/.local/share/opencode/auth.json with structure:
        {
          "anthropic": {
            "type": "oauth",
            "access": "<access_token>",
            "refresh": "<refresh_token>",
            "expires": <timestamp>
          },
          "github-copilot": {
            "type": "oauth",
            "refresh": "<github_oauth_token>",
            "access": "<copilot_api_token>",
            "expires": <timestamp>
          }
        }

        - anthropic credentials come from claude_code.auth.oauth
        - github-copilot.refresh comes from copilot_cli.auth.oauth.oauth_token
        - github-copilot.access (Copilot API token) is fetched dynamically by OpenCode
        """
        opencode_config = self._data.get('opencode', {})
        if not isinstance(opencode_config, dict):
            return

        # Skip if opencode is not enabled
        if not opencode_config.get('enabled', False):
            return

        # Skip if opencode.auth already has values
        if opencode_config.get('auth'):
            return

        auth = {}

        # Derive anthropic auth from Claude Code
        claude_config = self._data.get('claude_code', {})
        if isinstance(claude_config, dict):
            claude_oauth = claude_config.get('auth', {}).get('oauth', {})
            if claude_oauth.get('access_token') and claude_oauth.get('refresh_token'):
                auth['anthropic'] = {
                    'access_token': claude_oauth['access_token'],
                    'refresh_token': claude_oauth['refresh_token'],
                }
                if claude_oauth.get('expires_at'):
                    auth['anthropic']['expires_at'] = claude_oauth['expires_at']

        # Derive github-copilot auth from Copilot CLI
        copilot_config = self._data.get('copilot_cli', {})
        if isinstance(copilot_config, dict):
            copilot_oauth = copilot_config.get('auth', {}).get('oauth', {})
            if copilot_oauth.get('oauth_token'):
                auth['github_copilot'] = {
                    'oauth_token': copilot_oauth['oauth_token'],
                }
                # Note: access_token (Copilot API token) is fetched dynamically by OpenCode

        # Apply derived auth if any credentials were found
        if auth:
            if 'opencode' not in self._data:
                self._data['opencode'] = {}
            self._data['opencode']['auth'] = auth

    def _derive_opencode_providers(self):
        """Set OpenCode default model from Claude Code or Copilot CLI config.

        OpenCode has built-in support for anthropic and github-copilot providers.
        These don't need provider config - they only need auth.json (handled by
        _derive_opencode_auth). We just set the default model if not already set.

        Note: Custom providers (ollama, openai, etc.) should be configured
        explicitly in opencode.config.yaml under the 'providers' key.
        """
        opencode_config = self._data.get('opencode', {})
        if not isinstance(opencode_config, dict):
            return

        # Skip if opencode is not enabled
        if not opencode_config.get('enabled', False):
            return

        # Skip if model is already set
        if opencode_config.get('model'):
            return

        # Set default model from Claude Code config (anthropic provider)
        claude_config = self._data.get('claude_code', {})
        if isinstance(claude_config, dict) and claude_config.get('enabled', False):
            claude_model = claude_config.get('model', 'claude-sonnet-4-5-latest')
            # OpenCode uses format "anthropic/<model>"
            if '/' not in claude_model:
                opencode_model = f"anthropic/{claude_model}"
            else:
                opencode_model = claude_model

            if 'opencode' not in self._data:
                self._data['opencode'] = {}
            self._data['opencode']['model'] = opencode_model
            return

        # Fallback: Set default model from Copilot CLI config (github-copilot provider)
        copilot_config = self._data.get('copilot_cli', {})
        if isinstance(copilot_config, dict) and copilot_config.get('enabled', False):
            copilot_model = copilot_config.get('model', 'gpt-4')
            if '/' not in copilot_model:
                opencode_model = f"github-copilot/{copilot_model}"
            else:
                opencode_model = copilot_model

            if 'opencode' not in self._data:
                self._data['opencode'] = {}
            self._data['opencode']['model'] = opencode_model

    def _index_paths(self, obj, path):
        """Recursively index all paths in the config tree."""
        if isinstance(obj, dict):
            for key, value in obj.items():
                self._index_paths(value, path + [key])
        else:
            # Scalar or list - index this path
            path_str = '.'.join(path)
            normalized = self._normalize_path(path_str)
            if normalized not in self._paths:
                self._paths[normalized] = []
            self._paths[normalized].append((path, path_str))

    def _normalize_path(self, path_str):
        """Normalize a config path to env var format [A-Z_]+."""
        return re.sub(r'[^A-Za-z0-9]', '_', path_str).upper()

    def _path_score(self, path_str):
        """
        Score a path for tiebreaking. Higher score = higher priority.
        Prefer: most underscores > most dots > other delimiters
        """
        underscores = path_str.count('_')
        dots = path_str.count('.')
        return (underscores, dots)

    def _find_best_path(self, env_name):
        """
        Find the best matching config path for an env var name.
        Returns (path_parts, path_str, is_new) tuple.

        For partial/no matches, creates new path with max segmentation:
        remainder underscores become dots (new nesting levels).
        """
        # Exact match
        if env_name in self._paths:
            candidates = self._paths[env_name]
            if len(candidates) == 1:
                return (*candidates[0], False)
            # Tiebreak by score
            best = max(candidates, key=lambda c: self._path_score(c[1]))
            return (*best, False)

        # Partial match - find longest matching prefix
        best_match = None
        best_len = 0
        best_remainder = ''
        for normalized, candidates in self._paths.items():
            if env_name.startswith(normalized + '_'):
                if len(normalized) > best_len:
                    best_len = len(normalized)
                    best_remainder = env_name[len(normalized) + 1:]  # +1 for the _
                    best_match = max(candidates, key=lambda c: self._path_score(c[1]))

        if best_match:
            # Extend path with max segmentation (each _ becomes new level)
            path_parts, path_str = best_match
            new_segments = [s.lower() for s in best_remainder.split('_')]
            extended_path = list(path_parts) + new_segments
            extended_str = path_str + '.' + '.'.join(new_segments)
            return (extended_path, extended_str, True)

        # No match at all - create from scratch with max segmentation
        new_segments = [s.lower() for s in env_name.split('_')]
        return (new_segments, '.'.join(new_segments), True)

    def _cast_value(self, value):
        """Cast string value to JSON scalar type (bool, int, float, or string)."""
        # JSON booleans only (not YAML's yes/no/on/off)
        if value == 'true':
            return True
        if value == 'false':
            return False

        # Try integer
        try:
            return int(value)
        except ValueError:
            pass

        # Try float
        try:
            return float(value)
        except ValueError:
            pass

        # Keep as string
        return value

    def _apply_env_overrides(self, prefix):
        """Apply environment variables as config overrides."""
        for env_name, env_value in os.environ.items():
            # Skip if prefix specified and doesn't match
            if prefix and not env_name.startswith(prefix):
                continue

            # Strip prefix for matching
            match_name = env_name[len(prefix):] if prefix else env_name

            # Find matching path
            path_parts, path_str, is_new = self._find_best_path(match_name)

            # Navigate to parent, creating dicts as needed
            obj = self._data
            for part in path_parts[:-1]:
                if part not in obj:
                    obj[part] = {}
                obj = obj[part]
            obj[path_parts[-1]] = self._cast_value(env_value)

    def __getattr__(self, name):
        if name.startswith('_'):
            raise AttributeError(name)
        return self._data.get(name, {})

    def __getitem__(self, key):
        return self._data[key]

    def get(self, key, default=None):
        """Get a top-level config key with optional default."""
        return self._data.get(key, default)

    def to_dict(self):
        """Export as dict for Jinja2 context (namespaced)"""
        return dict(self._data)
