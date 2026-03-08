"""IronPython-compatible cloud-init renderer."""

import sys
import json
import os
from ruamel.yaml import YAML
from jinja2 import Environment, FileSystemLoader

from . import filters
from .composer import deep_merge


def discover_fragments(repo_root, base_dirs=None):
    """Discover fragments by finding build.yaml files under repo_root."""
    if base_dirs is None:
        base_dirs = ['book-1-foundation', 'book-2-cloud']

    fragments = []
    _y = YAML()
    for base_dir in base_dirs:
        search = os.path.join(repo_root, base_dir)
        for dirpath, _, files in os.walk(search):
            if 'build.yaml' not in files:
                continue
            with open(os.path.join(dirpath, 'build.yaml')) as f:
                meta = _y.load(f)
            meta['_path'] = dirpath
            fragments.append(meta)
    return sorted(fragments, key=lambda f: f.get('build_order', 999))


def create_environment(repo_root, template_dirs=None):
    """Create Jinja2 environment with custom filters."""
    if template_dirs is None:
        template_dirs = ['book-1-foundation', 'book-2-cloud']
    abs_dirs = [os.path.join(repo_root, d) for d in template_dirs]
    env = Environment(loader=FileSystemLoader(abs_dirs), keep_trailing_newline=True)
    env.filters['shell_quote'] = filters.shell_quote
    env.filters['shell_array'] = filters.shell_array
    env.filters['sha512_hash'] = filters.sha512_hash
    env.filters['ip_only'] = filters.ip_only
    env.filters['cidr_only'] = filters.cidr_only
    env.filters['to_yaml'] = filters.to_yaml
    env.filters['to_base64'] = filters.to_base64

    return env


def render_cloud_init(ctx, env, fragments):
    """Render and merge cloud-init fragments, return as dict."""
    merged = {}
    _y = YAML()
    for frag in fragments:
        tpl_path = os.path.join(frag['_path'], 'fragment.yaml.tpl')
        if not os.path.exists(tpl_path):
            continue
        for sp in env.loader.searchpath:
            rel = os.path.relpath(tpl_path, sp)
            if not rel.startswith('..'):
                rendered = env.get_template(rel.replace('\\', '/')).render(**ctx)
                data = _y.load(rendered)
                if data:
                    merged = deep_merge(merged, data)
                break
    return merged


def main():
    """Read JSON context from stdin, render cloud-init, write YAML to stdout."""
    import io
    raw = sys.stdin.read()
    ctx = json.loads(raw)
    repo_root = ctx.pop('__repo_root__')
    env = create_environment(repo_root)
    frags = discover_fragments(repo_root)
    merged = render_cloud_init(ctx, env, frags)
    _y = YAML()
    _y.default_flow_style = False
    buf = io.StringIO()
    _y.dump(merged, buf)
    sys.stdout.write('#cloud-config\n' + buf.getvalue())

if __name__ == '__main__':
    main()
