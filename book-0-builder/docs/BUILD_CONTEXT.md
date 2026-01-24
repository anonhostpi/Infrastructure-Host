# 3.1 BuildContext

The `BuildContext` class loads all configuration files and exposes them to Jinja2 templates as a namespaced dictionary. Environment variables can override any config value.

## Implementation

```python
# builder/context.py
import os
import re
from pathlib import Path
import yaml

class BuildContext:
    """
    Loads all *.config.yaml files from src/config/ directory.
    Each file becomes a top-level key (filename before .config.yaml).

    Auto-unwrap: If a config has only one top-level key AND that key
    matches the filename, unwrap it. e.g., identity.config.yaml with
    'identity:' unwraps, but network.config.yaml with 'host:' does not.

    Environment variables override config values after loading.
    """

    def __init__(self, configs_dir='src/config', env_prefix='AUTOINSTALL_'):
        self._data = {}
        self._paths = {}  # Maps normalized env name -> (path, original_path_str)

        # Load all config files
        for filepath in Path(configs_dir).glob('*.config.yaml'):
            key = filepath.name.replace('.config.yaml', '')
            with open(filepath) as f:
                content = yaml.safe_load(f)
                # Auto-unwrap only if single key matches filename
                if isinstance(content, dict) and len(content) == 1:
                    only_key = next(iter(content.keys()))
                    if only_key == key:
                        content = content[only_key]
                self._data[key] = content

        # Build path index for env var matching
        self._index_paths(self._data, [])

        # Apply environment variable overrides
        self._apply_env_overrides(env_prefix)

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

    def to_dict(self):
        """Export as dict for Jinja2 context (namespaced)"""
        return dict(self._data)
```

## Environment Variable Overrides

Environment variables can override any scalar config value. Since env vars are restricted to `[A-Z_]+`, BuildContext maps them to config paths using normalization and matching rules.

### Path Normalization

Config paths are normalized by replacing all non-alphanumeric characters with underscores and uppercasing:

| Config Path | Normalized |
|-------------|------------|
| `network.hostname` | `NETWORK_HOSTNAME` |
| `network.dns-servers` | `NETWORK_DNS_SERVERS` |
| `storage.zfs_pool` | `STORAGE_ZFS_POOL` |
| `api.base/url:port` | `API_BASE_URL_PORT` |

### Path Resolution

When multiple config paths normalize to the same env var name, BuildContext resolves ambiguity:

**1. Longest Match Wins**

For partial matches, the longest matching path takes precedence:

```
Env var: NETWORK_DNS_SERVERS_PRIMARY

Paths:
  network.dns         -> NETWORK_DNS (partial, length 11)
  network.dns-servers -> NETWORK_DNS_SERVERS (partial, length 19) ← wins
```

**2. Tiebreaker: Delimiter Priority**

For paths with equal match length, prefer paths with longer env-var names (more underscores), then prefer higher segmentation (more dots):

```
Env var: ROOTS_BASE_TRUNK_BRANCH

Paths (all normalize to same):
  roots_base.trunk-branch  -> score (1 underscore, 1 dot)
  roots.base_trunk-branch  -> score (1 underscore, 1 dot)  ← tie
  roots_base_trunk.branch  -> score (2 underscores, 1 dot) ← wins
```

**3. Path Creation with Maximum Segmentation**

For partial matches or no matches, new paths are created with maximum segmentation - each underscore in the remainder becomes a new nesting level (dot):

```yaml
Env var: AUTOINSTALL_DOC_ROOT_GRANDPARENT_PARENT_CHILD=value

Existing config:
  doc_root:
    grandparent: existing_value

Match: DOC_ROOT_GRANDPARENT (partial)
Remainder: PARENT_CHILD

Result (max segmentation - each _ becomes .):
  doc_root:
    grandparent:
      parent:
        child: value

NOT this (low segmentation):
  doc_root:
    grandparent:
      parent_child: value
```

For env vars with no matching prefix at all, the entire name is segmented:

```yaml
Env var: AUTOINSTALL_NEW_SECTION_KEY_NAME=value

Result:
  new:
    section:
      key:
        name: value
```

### Value Casting

Env var values are cast to JSON scalar types:

| Value | Type | Result |
|-------|------|--------|
| `true` | boolean | `True` |
| `false` | boolean | `False` |
| `42` | integer | `42` |
| `3.14` | float | `3.14` |
| `hello` | string | `"hello"` |

**Note:** YAML-style booleans (`yes`, `no`, `on`, `off`) are NOT converted - only JSON `true`/`false`.

### Usage Examples

```bash
# Override network hostname (default prefix: AUTOINSTALL_)
export AUTOINSTALL_NETWORK_HOSTNAME=prod-server
export AUTOINSTALL_NETWORK_GATEWAY=10.0.0.1
export AUTOINSTALL_IDENTITY_USERNAME=admin

# Build with env overrides
python -m builder render cloud-init -o output/cloud-init.yaml
```

```python
# Default - only AUTOINSTALL_* env vars are considered
ctx = BuildContext('src/config')

# Custom prefix
ctx = BuildContext('src/config', env_prefix='BUILD_')

# No prefix - match all env vars (not recommended)
ctx = BuildContext('src/config', env_prefix='')
```

### Limitations

- Only scalar values can be set (not lists or dicts)
- New paths are always created with maximum segmentation (no way to create `parent_child` key via env var)

## Auto-Unwrap Behavior

When a configuration file has only one top-level key **and that key matches the filename**, BuildContext automatically unwraps it to avoid redundant access patterns.

### Example: Unwrap Occurs

`identity.config.yaml` with matching key:
```yaml
identity:          # ← matches filename "identity"
  username: admin
  password: secret
```

Result - unwrapped:
```jinja
{{ identity.username }}  {# Clean access #}
```

### Example: Unwrap Skipped

`network.config.yaml` with non-matching key:
```yaml
host:              # ← does NOT match filename "network"
  ip: 192.168.1.1
  gateway: 192.168.1.1
```

Result - not unwrapped:
```jinja
{{ network.host.ip }}  {# Key preserved #}
```

## Usage in Templates

Configuration files are namespaced by their filename (minus `.config.yaml`):

```yaml
# From network.config.yaml
hostname: {{ network.hostname }}
gateway: {{ network.gateway }}
dns_servers: {{ network.dns_servers }}

# From identity.config.yaml
username: {{ identity.username }}
password: {{ identity.password | sha512_hash }}
```

## Programmatic Usage

```python
from builder.context import BuildContext

# Load all configs from src/config/
ctx = BuildContext('src/config')

# Access via attribute
print(ctx.network.hostname)
print(ctx.identity.username)

# Access via subscript
print(ctx['network']['gateway'])

# Export for Jinja2
template.render(**ctx.to_dict())
```

## Configuration File Discovery

BuildContext automatically discovers all `*.config.yaml` files in the specified directory:

```
src/config/
├── network.config.yaml    -> ctx.network.*
├── identity.config.yaml   -> ctx.identity.*
└── storage.config.yaml    -> ctx.storage.*
```

Adding a new configuration file requires no code changes - it will be automatically loaded and available in templates.
