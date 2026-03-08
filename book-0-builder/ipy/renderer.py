"""IronPython-compatible cloud-init renderer."""

import sys, json, os
from ruamel.yaml import YAML
from jinja2 import Environment, FileSystemLoader
import filters
from composer import deep_merge

def discover_fragments(repo_root, base_dirs=None): pass  # WIP
def create_environment(repo_root, template_dirs=None): pass  # WIP
def render_cloud_init(ctx, env, fragments): pass  # WIP
def main(): pass  # WIP

if __name__ == '__main__':
    main()
