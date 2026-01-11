"""Template rendering functions for deployment artifacts."""

from pathlib import Path
import yaml
from jinja2 import Environment, FileSystemLoader

from . import filters
from .composer import deep_merge


# Custom YAML representer for multiline strings using literal block scalars
def str_representer(dumper, data):
    """Use literal block scalar (|) for multiline strings.

    Also forces quoting for numeric-looking strings (like permissions '644')
    to ensure cloud-init schema validation passes.
    """
    if '\n' in data:
        # Use literal block style for multiline
        return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')
    # Force single quotes for strings that look like numbers (e.g., '0644', '0755')
    # This ensures cloud-init doesn't interpret them as integers
    # Matches: pure digits, or leading 0 followed by digits (octal-like permissions)
    if data.isdigit() or (len(data) > 1 and data[0] == '0' and data[1:].isdigit()):
        return dumper.represent_scalar('tag:yaml.org,2002:str', data, style="'")
    return dumper.represent_scalar('tag:yaml.org,2002:str', data)


# Register the custom representer
yaml.add_representer(str, str_representer)


def create_environment(template_dir='src'):
    """Create Jinja2 environment with custom filters."""
    env = Environment(
        loader=FileSystemLoader(template_dir),
        keep_trailing_newline=True,
    )

    # Register custom filters
    env.filters['shell_quote'] = filters.shell_quote
    env.filters['shell_array'] = filters.shell_array
    env.filters['sha512_hash'] = filters.sha512_hash
    env.filters['ip_only'] = filters.ip_only
    env.filters['cidr_only'] = filters.cidr_only
    env.filters['to_yaml'] = filters.to_yaml

    return env


# Global Jinja2 environment
_env = None


def get_environment():
    """Get or create the global Jinja2 environment."""
    global _env
    if _env is None:
        _env = create_environment('src')
    return _env


def render_text(ctx, template_path, **extra_context):
    """Render a template, return as string."""
    env = get_environment()
    template = env.get_template(template_path)
    return template.render(**ctx.to_dict(), **extra_context)


def render_scripts(ctx):
    """Render all script templates, return as dict."""
    scripts_dir = Path('src/scripts')
    scripts = {}

    if not scripts_dir.exists():
        return scripts

    for tpl_path in scripts_dir.glob('*.tpl'):
        # Keep original filename (e.g., "early-net.sh")
        filename = tpl_path.name.removesuffix('.tpl')
        # Use forward slashes for Jinja2 (cross-platform)
        template_path = tpl_path.relative_to('src').as_posix()
        rendered = render_text(ctx, template_path)
        scripts[filename] = rendered

    return scripts


def render_script(ctx, input_path, output_path):
    """Render a script template to output file."""
    # Handle path relative to src/
    if input_path.startswith('src/'):
        template_path = input_path[4:]  # Remove 'src/' prefix
    else:
        template_path = input_path

    result = render_text(ctx, template_path)

    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', newline='\n') as f:
        f.write(result)


def get_available_fragments():
    """Return list of available fragment names (without path or extension)."""
    fragments_dir = Path('src/autoinstall/cloud-init')
    if not fragments_dir.exists():
        return []
    return sorted([
        p.name.removesuffix('.yaml.tpl')
        for p in fragments_dir.glob('*.yaml.tpl')
    ])


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


def render_cloud_init(ctx, include=None, exclude=None):
    """Render and merge cloud-init fragments, return as dict.

    Args:
        ctx: Build context
        include: List of fragment names to include (default: all)
        exclude: List of fragment names to exclude (default: none)

    Fragment names are matched without path or extension, e.g.:
        "20-users" matches "src/autoinstall/cloud-init/20-users.yaml.tpl"

    Raises:
        FragmentValidationError: If a fragment produces invalid YAML
    """
    fragments_dir = Path('src/autoinstall/cloud-init')
    scripts = render_scripts(ctx)

    merged = {}

    if not fragments_dir.exists():
        return merged

    for tpl_path in sorted(fragments_dir.glob('*.yaml.tpl')):
        fragment_name = tpl_path.name.removesuffix('.yaml.tpl')

        # Filter by include list (if specified)
        if include is not None and fragment_name not in include:
            continue

        # Filter by exclude list (if specified)
        if exclude is not None and fragment_name in exclude:
            continue

        # Use forward slashes for Jinja2 (cross-platform)
        template_path = tpl_path.relative_to('src').as_posix()
        rendered = render_text(ctx, template_path, scripts=scripts)

        # Validate YAML with helpful error message
        try:
            fragment = yaml.safe_load(rendered)
        except yaml.YAMLError as e:
            raise FragmentValidationError(fragment_name, e, rendered) from e

        if fragment:
            merged = deep_merge(merged, fragment)

    return merged


def render_cloud_init_to_file(ctx, output_path, include=None, exclude=None):
    """Render cloud-init to output file.

    Args:
        ctx: Build context
        output_path: Path to write output
        include: List of fragment names to include (default: all)
        exclude: List of fragment names to exclude (default: none)
    """
    merged = render_cloud_init(ctx, include=include, exclude=exclude)

    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', newline='\n') as f:
        f.write('#cloud-config\n')
        yaml.dump(merged, f, default_flow_style=False, sort_keys=False, width=1000)


def render_autoinstall(ctx):
    """Render autoinstall user-data, return as string."""
    scripts = render_scripts(ctx)
    cloud_init = render_cloud_init(ctx)

    return render_text(
        ctx,
        'autoinstall/base.yaml.tpl',
        scripts=scripts,
        cloud_init=cloud_init,
    )


def render_autoinstall_to_file(ctx, output_path):
    """Render autoinstall to output file."""
    result = render_autoinstall(ctx)

    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', newline='\n') as f:
        f.write(result)
