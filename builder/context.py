"""BuildContext loads configuration files and exposes them to templates."""

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

    def get(self, key, default=None):
        """Get a top-level config key with optional default."""
        return self._data.get(key, default)

    def to_dict(self):
        """Export as dict for Jinja2 context (namespaced)"""
        return dict(self._data)
