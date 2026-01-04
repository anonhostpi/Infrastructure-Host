"""Template rendering functions for deployment artifacts."""

from pathlib import Path
import yaml
from jinja2 import Environment, FileSystemLoader

from . import filters
from .composer import deep_merge


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
        rendered = render_text(ctx, str(tpl_path.relative_to('src')))
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


def render_cloud_init(ctx):
    """Render and merge cloud-init fragments, return as dict."""
    fragments_dir = Path('src/autoinstall/cloud-init')
    scripts = render_scripts(ctx)

    merged = {}

    if not fragments_dir.exists():
        return merged

    for tpl_path in sorted(fragments_dir.glob('*.yaml.tpl')):
        rendered = render_text(ctx, str(tpl_path.relative_to('src')), scripts=scripts)
        fragment = yaml.safe_load(rendered)
        if fragment:
            merged = deep_merge(merged, fragment)

    return merged


def render_cloud_init_to_file(ctx, output_path):
    """Render cloud-init to output file."""
    merged = render_cloud_init(ctx)

    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', newline='\n') as f:
        f.write('#cloud-config\n')
        yaml.dump(merged, f, default_flow_style=False, sort_keys=False)


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
