"""CLI entry point for the builder module."""

import argparse
import sys

from .context import BuildContext
from .renderer import render_script, render_cloud_init_to_file, render_autoinstall_to_file


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

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    ctx = BuildContext(args.config_dir)

    if args.target == 'script':
        if not args.input:
            print('Error: input path required for script target', file=sys.stderr)
            sys.exit(1)
        render_script(ctx, args.input, args.output)
    elif args.target == 'cloud-init':
        render_cloud_init_to_file(ctx, args.output)
    elif args.target == 'autoinstall':
        render_autoinstall_to_file(ctx, args.output)

    print(f'Generated: {args.output}')


if __name__ == '__main__':
    main()
