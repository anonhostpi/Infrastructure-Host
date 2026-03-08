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
    scripts = render_scripts(ctx)
    merged = {}

    for fragment in discover_fragments():
        fragment_name = fragment['name']
        tpl_path = fragment['_path'] / 'fragment.yaml.tpl'

        if not tpl_path.exists():
            continue

        # Filter by include list (if specified)
        if include is not None and fragment_name not in include:
            continue

        # Filter by exclude list (if specified)
        if exclude is not None and fragment_name in exclude:
            continue

        # Always include iso_required fragments for ISO builds
        if for_iso and fragment.get('iso_required', False):
            pass  # Don't filter this fragment
        elif layer is not None:
            # Filter by layer (if specified)
            frag_layer = fragment.get('build_layer', 999)
            # build_layer can be int or list of ints
            if isinstance(frag_layer, list):
                if not any(l <= layer for l in frag_layer):
                    continue
            elif frag_layer > layer:
                continue

        template_path = tpl_path.as_posix()
        rendered = render_text(ctx, template_path, scripts=scripts)

        # Validate YAML with helpful error message
        try:
            fragment = yaml.safe_load(rendered)
        except yaml.YAMLError as e:
            raise FragmentValidationError(fragment_name, e, rendered) from e

        if fragment:
            merged = deep_merge(merged, fragment)

    return merged


def render_cloud_init_to_file(ctx, output_path, include=None, exclude=None, layer=None, for_iso=False):
    """Render cloud-init to output file.

    Args:
        ctx: Build context
        output_path: Path to write output
        include: List of fragment names to include (default: all)
        exclude: List of fragment names to exclude (default: none)
        layer: Maximum build_layer to include (default: all)
        for_iso: If True, always include iso_required fragments
    """
    merged = render_cloud_init(ctx, include=include, exclude=exclude, layer=layer, for_iso=for_iso)
    artifacts.write(
        None, 'cloud_init', output_path,
        content='#cloud-config\n',
        writer=lambda f: yaml.dump(merged, f, default_flow_style=False, sort_keys=False, width=1000)
    )


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
