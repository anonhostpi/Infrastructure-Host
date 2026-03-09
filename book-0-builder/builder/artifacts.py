"""Build artifact tracking for output manifest."""

import os
from datetime import datetime, timezone
from ruamel.yaml import YAML

DEFAULT_PATH = 'output/artifacts.yaml'


def load(path=DEFAULT_PATH):
    """Load existing artifacts.yaml or return empty structure."""
    if os.path.exists(path):
        with open(path) as f:
            return YAML().load(f) or {}
    return {}


def save(artifacts, path=DEFAULT_PATH, host='unknown'):
    """Save artifacts manifest to file."""
    artifacts['build_timestamp'] = datetime.now(timezone.utc).isoformat()
    artifacts['build_host'] = host
    out_dir = os.path.dirname(path)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)
    with open(path, 'w', newline='\n') as f:
        _y = YAML()
        _y.default_flow_style = False
        _y.dump(artifacts, f)


def update(category, name, value, path=DEFAULT_PATH, host='unknown'):
    """Update a single artifact entry and save.

    Args:
        category: Category key (e.g., 'scripts') or None for top-level
        name: Artifact name/key
        value: Artifact value (typically a path)
        path: Path to artifacts.yaml file
        host: Build host identifier ('worker' or 'host')
    """
    artifacts = load(path)
    if category:
        if category not in artifacts:
            artifacts[category] = {}
        artifacts[category][name] = value
    else:
        artifacts[name] = value
    save(artifacts, path, host=host)
    return artifacts


def write(category, name, output_path, content=None, writer=None, artifacts_path=DEFAULT_PATH, host='unknown'):
    """Write an artifact file and track it.

    Args:
        category: Category key (e.g., 'scripts') or None for top-level
        name: Artifact name/key
        output_path: Path to write the artifact
        content: Optional string content to write first
        writer: Optional callback for additional writes, receives file handle
                e.g., lambda f: yaml.dump(data, f, ...)
        artifacts_path: Path to artifacts.yaml file
        host: Build host identifier ('worker' or 'host')
    """
    out_dir = os.path.dirname(output_path)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)
    with open(output_path, 'w', newline='\n') as f:
        if content is not None:
            f.write(content)
        if writer is not None:
            writer(f)
    update(category, name, output_path, path=artifacts_path, host=host)
