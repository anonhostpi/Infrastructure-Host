"""Template rendering functions for deployment artifacts."""

import os
from ruamel.yaml import YAML
from jinja2 import Environment, FileSystemLoader

from . import artifacts
from . import filters
from .composer import deep_merge



def discover_fragments(repo_root=None, base_dirs=None):
    """Discover fragments by finding build.yaml files."""
    if base_dirs is None:
        base_dirs = ['book-1-foundation', 'book-2-cloud']

    fragments = []
    for base_dir in base_dirs:
        search = os.path.join(repo_root, base_dir) if repo_root else base_dir
        for dirpath, _, files in os.walk(search):
            if 'build.yaml' not in files:
                continue
            with open(os.path.join(dirpath, 'build.yaml')) as f:
                meta = YAML().load(f)
            meta['_path'] = dirpath
            fragments.append(meta)
    return sorted(fragments, key=lambda f: f.get('build_order', 999))


def create_environment(repo_root=None, template_dirs=None):
    """Create Jinja2 environment with custom filters."""
    if template_dirs is None:
        template_dirs = ['book-1-foundation', 'book-2-cloud']
    if repo_root:
        abs_dirs = [os.path.join(repo_root, d) for d in template_dirs]
    else:
        abs_dirs = template_dirs
    env = Environment(
        loader=FileSystemLoader(abs_dirs),
        keep_trailing_newline=True,
    )

    # Register custom filters
    env.filters['shell_quote'] = filters.shell_quote
    env.filters['shell_array'] = filters.shell_array
    env.filters['sha512_hash'] = filters.sha512_hash
    env.filters['ip_only'] = filters.ip_only
    env.filters['cidr_only'] = filters.cidr_only
    env.filters['to_yaml'] = filters.to_yaml
    env.filters['to_base64'] = filters.to_base64

    return env


# Global Jinja2 environment
_env = None


def get_environment():
    """Get or create the global Jinja2 environment."""
    global _env
    if _env is None:
        _env = create_environment()
    return _env


def render_text(ctx, template_path, **extra_context):
    """Render a template, return as string."""
    env = get_environment()
    template = env.get_template(template_path)
    return template.render(**ctx.to_dict(), **extra_context)


def render_scripts(ctx):
    """Render all script templates from discovered fragments."""
    scripts = {}
    for fragment in discover_fragments():
        scripts_dir = os.path.join(str(fragment['_path']), 'scripts')
        if not os.path.exists(scripts_dir):
            continue
        for fname in os.listdir(scripts_dir):
            if not fname.endswith('.sh.tpl'):
                continue
            tpl_path = os.path.join(scripts_dir, fname)
            filename = fname[:-4] if fname.endswith('.tpl') else fname
            template_path = tpl_path.replace('\\', '/')
            rendered = render_text(ctx, template_path)
            scripts[filename] = rendered
    return scripts


def render_script(ctx, input_path, output_path):
    """Render a script template to output file."""
    template_path = input_path
    result = render_text(ctx, template_path)
    artifacts.write('scripts', os.path.basename(output_path), output_path, content=result)


def get_available_fragments():
    """Return list of available fragment names from discovered build.yaml files."""
    return [f['name'] for f in discover_fragments()]


class FragmentValidationError(Exception):
    """Raised when a cloud-init fragment produces invalid YAML."""
    def __init__(self, fragment_name, original_error, rendered_content):
        self.fragment_name = fragment_name
        self.original_error = original_error
        self.rendered_content = rendered_content
        super().__init__(
            f"Fragment '{fragment_name}' produced invalid YAML:\n"
            f"  {original_error}\n"
            f"Rendered content:\n{self._numbered_content()}"
        )

    def _numbered_content(self):
        """Return rendered content with line numbers for debugging."""
        lines = self.rendered_content.split('\n')
        return '\n'.join(f"  {i+1:3d}: {line}" for i, line in enumerate(lines))


def render_cloud_init(ctx, include=None, exclude=None, layer=None, for_iso=False):
    """Render and merge cloud-init fragments, return as dict.

    Args:
        ctx: Build context
        include: List of fragment names to include (default: all)
        exclude: List of fragment names to exclude (default: none)
        layer: Maximum build_layer to include (default: all)
        for_iso: If True, always include iso_required fragments

    Fragment names are matched against the 'name' field in build.yaml.

    Raises:
        FragmentValidationError: If a fragment produces invalid YAML
    """
    scripts = render_scripts(ctx)
    merged = {}

    for fragment in discover_fragments():
        fragment_name = fragment['name']
        tpl_path = os.path.join(str(fragment['_path']), 'fragment.yaml.tpl')

        if not os.path.exists(tpl_path):
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

        template_path = tpl_path.replace('\\', '/')
        rendered = render_text(ctx, template_path, scripts=scripts)

        # Validate YAML with helpful error message
        try:
            fragment = YAML().load(rendered)
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
