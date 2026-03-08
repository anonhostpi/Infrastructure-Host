"""IronPython-compatible cloud-init renderer."""

import sys, json, os
from ruamel.yaml import YAML
from jinja2 import Environment, FileSystemLoader
import filters
from composer import deep_merge

def discover_fragments(repo_root, base_dirs=None):
    """Discover fragments by finding build.yaml files under repo_root."""
    if base_dirs is None:
        base_dirs = ['book-1-foundation', 'book-2-cloud']
    fragments = []
    _y = YAML()
    for base_dir in base_dirs:
        search = os.path.join(repo_root, base_dir)
        for dirpath, _, files in os.walk(search):
            if 'build.yaml' in files:
                fpath = os.path.join(dirpath, 'build.yaml')
                with open(fpath) as f:
                    meta = _y.load(f)
                meta['_path'] = dirpath
                fragments.append(meta)
    return sorted(fragments, key=lambda x: x.get('build_order', 999))
def create_environment(repo_root, template_dirs=None): pass  # WIP
def render_cloud_init(ctx, env, fragments): pass  # WIP
def main(): pass  # WIP

if __name__ == '__main__':
    main()
