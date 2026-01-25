"""CLI entry point for the builder module."""

import argparse
import sys

from . import artifacts
from .context import BuildContext
from .renderer import (
    render_script,
    render_cloud_init_to_file,
    render_autoinstall_to_file,
    get_available_fragments,
)


def main():
    parser = argparse.ArgumentParser(
        prog='builder',
        description='Build deployment artifacts from templates'
    )
    subparsers = parser.add_subparsers(dest='command')

    # render subcommand
    render_parser = subparsers.add_parser('render', help='Render templates')
    render_parser.add_argument(
        'target',
        choices=['script', 'cloud-init', 'autoinstall'],
        help='Type of artifact to render'
    )
    render_parser.add_argument(
        'input',
        nargs='?',
        help='Input template path (required for script target)'
    )
    render_parser.add_argument(
        '-o', '--output',
        required=True,
        help='Output file path'
    )
    render_parser.add_argument(
        '-c', '--config-dir',
        default='src/config',
        help='Configuration directory (default: src/config)'
    )
    render_parser.add_argument(
        '-i', '--include',
        action='append',
        metavar='FRAGMENT',
        help='Include only specified fragments (can be repeated). '
             'Use "python -m builder list-fragments" to see available fragments.'
    )
    render_parser.add_argument(
        '-x', '--exclude',
        action='append',
        metavar='FRAGMENT',
        help='Exclude specified fragments (can be repeated). '
             'Use "python -m builder list-fragments" to see available fragments.'
    )
    render_parser.add_argument(
        '-l', '--layer',
        type=int,
        metavar='LAYER',
        help='Include fragments up to build_layer N'
    )

    # list-fragments subcommand
    list_parser = subparsers.add_parser(
        'list-fragments',
        help='List available cloud-init fragments'
    )

    # artifacts subcommand
    artifacts_parser = subparsers.add_parser(
        'artifacts',
        help='Manage build artifacts manifest'
    )
    artifacts_parser.add_argument(
        'action',
        choices=['set', 'show'],
        help='Action to perform'
    )
    artifacts_parser.add_argument(
        'name',
        nargs='?',
        help='Artifact name (e.g., "iso", "cloud_init", or "scripts:early-net.sh")'
    )
    artifacts_parser.add_argument(
        'value',
        nargs='?',
        help='Artifact value (path)'
    )
    artifacts_parser.add_argument(
        '-f', '--file',
        default='output/artifacts.yaml',
        help='Artifacts file path (default: output/artifacts.yaml)'
    )

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    # Handle list-fragments command
    if args.command == 'list-fragments':
        fragments = get_available_fragments()
        if not fragments:
            print('No fragments found in src/autoinstall/cloud-init/')
            sys.exit(1)
        print('Available cloud-init fragments:')
        for f in fragments:
            print(f'  {f}')
        sys.exit(0)

    # Handle artifacts command
    if args.command == 'artifacts':
        if args.action == 'show':
            data = artifacts.load(args.file)
            if data:
                import yaml
                print(yaml.dump(data, default_flow_style=False, sort_keys=False))
            else:
                print('No artifacts found')
            sys.exit(0)

        if args.action == 'set':
            if not args.name or not args.value:
                print('Error: name and value required for set action', file=sys.stderr)
                sys.exit(1)

            # Parse "category:name" or just "name" for top-level
            if ':' in args.name:
                category, name = args.name.split(':', 1)
            else:
                category, name = None, args.name

            artifacts.update(category, name, args.value, path=args.file)
            print(f'Updated: {args.name} = {args.value}')
            sys.exit(0)

    # Handle render command
    ctx = BuildContext(args.config_dir)

    if args.target == 'script':
        if not args.input:
            print('Error: input path required for script target', file=sys.stderr)
            sys.exit(1)
        render_script(ctx, args.input, args.output)
    elif args.target == 'cloud-init':
        render_cloud_init_to_file(
            ctx,
            args.output,
            include=args.include,
            exclude=args.exclude,
            layer=args.layer
        )
    elif args.target == 'autoinstall':
        if args.include or args.exclude:
            print('Warning: --include/--exclude only apply to cloud-init target',
                  file=sys.stderr)
        render_autoinstall_to_file(ctx, args.output)

    print(f'Generated: {args.output}')


if __name__ == '__main__':
    main()
