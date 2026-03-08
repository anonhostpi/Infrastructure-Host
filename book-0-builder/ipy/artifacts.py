"""Build artifact tracking for output manifest."""

from pathlib import Path
from datetime import datetime, timezone
import yaml

DEFAULT_PATH = 'output/artifacts.yaml'


def load(path=DEFAULT_PATH):
    """Load existing artifacts.yaml or return empty structure."""
    p = Path(path)
    if p.exists():
        with open(p) as f:
            return yaml.safe_load(f) or {}
    return {}


def save(artifacts, path=DEFAULT_PATH):
    """Save artifacts manifest to file."""
    artifacts['build_timestamp'] = datetime.now(timezone.utc).isoformat()
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    with open(path, 'w', newline='\n') as f:
        yaml.dump(artifacts, f, default_flow_style=False, sort_keys=False)


def update(category, name, value, path=DEFAULT_PATH):
    """Update a single artifact entry and save.

    Args:
        category: Category key (e.g., 'scripts') or None for top-level
        name: Artifact name/key
        value: Artifact value (typically a path)
        path: Path to artifacts.yaml file
    """
    artifacts = load(path)
    if category:
        if category not in artifacts:
            artifacts[category] = {}
        artifacts[category][name] = value
    else:
        artifacts[name] = value
    save(artifacts, path)
    return artifacts


def write(category, name, output_path, content=None, writer=None, artifacts_path=DEFAULT_PATH):
    """Write an artifact file and track it.

    Args:
        category: Category key (e.g., 'scripts') or None for top-level
        name: Artifact name/key
        output_path: Path to write the artifact
        content: Optional string content to write first
        writer: Optional callback for additional writes, receives file handle
                e.g., lambda f: yaml.dump(data, f, ...)
        artifacts_path: Path to artifacts.yaml file
    """
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', newline='\n') as f:
        if content is not None:
            f.write(content)
        if writer is not None:
            writer(f)
    update(category, name, output_path, path=artifacts_path)
