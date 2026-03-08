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


def render_autoinstall(ctx):
    """Render autoinstall user-data, return as string."""
    scripts = render_scripts(ctx)
    # Autoinstall is always for ISO, so include iso_required fragments
    cloud_init = render_cloud_init(ctx, for_iso=True)

    return render_text(
        ctx,
        'book-1-foundation/base/autoinstall.yaml.tpl',
        scripts=scripts,
        cloud_init=cloud_init,
    )


def render_autoinstall_to_file(ctx, output_path):
    """Render autoinstall to output file."""
    result = render_autoinstall(ctx)
    artifacts.write(None, 'autoinstall', output_path, content=result)
