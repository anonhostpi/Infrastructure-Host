"""CLI entry point for the builder module."""

import argparse
import sys

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

    # list-fragments subcommand
    list_parser = subparsers.add_parser(
        'list-fragments',
        help='List available cloud-init fragments'
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
            exclude=args.exclude
        )
    elif args.target == 'autoinstall':
        if args.include or args.exclude:
            print('Warning: --include/--exclude only apply to cloud-init target',
                  file=sys.stderr)
        render_autoinstall_to_file(ctx, args.output)

    print(f'Generated: {args.output}')


if __name__ == '__main__':
    main()
