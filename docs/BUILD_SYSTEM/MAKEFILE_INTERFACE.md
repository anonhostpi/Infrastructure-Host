# 3.4 Makefile Interface

The Makefile provides a standard interface for building deployment artifacts with proper dependency tracking.

## Makefile

```makefile
.PHONY: all clean scripts cloud-init autoinstall iso

# Source dependencies
CONFIGS := $(wildcard src/config/*.config.yaml)
SCRIPTS := $(wildcard src/scripts/*.tpl)
CLOUD_INIT_FRAGMENTS := $(wildcard src/autoinstall/cloud-init/*.yaml.tpl)
AUTOINSTALL_TEMPLATES := $(wildcard src/autoinstall/*.yaml.tpl)

# Default: build everything
all: scripts cloud-init autoinstall

# Generate shell scripts (standalone, for reference/debugging)
scripts: output/scripts/early-net.sh output/scripts/net-setup.sh

output/scripts/%.sh: src/scripts/%.sh.tpl $(CONFIGS)
	python -m builder render script $< -o $@

# Generate cloud-init config (renders scripts internally)
cloud-init: output/cloud-init.yaml

output/cloud-init.yaml: $(CLOUD_INIT_FRAGMENTS) $(SCRIPTS) $(CONFIGS)
	python -m builder render cloud-init -o $@

# Generate autoinstall user-data (renders scripts + cloud-init internally)
autoinstall: output/user-data

output/user-data: $(AUTOINSTALL_TEMPLATES) $(CLOUD_INIT_FRAGMENTS) $(SCRIPTS) $(CONFIGS)
	python -m builder render autoinstall -o $@

# Build ISO (runs in multipass VM)
iso: output/user-data
	./build-iso.sh

clean:
	rm -rf output/*
```

## Targets

| Target | Description | Output |
|--------|-------------|--------|
| `all` | Build all artifacts (default) | All outputs |
| `scripts` | Generate shell scripts | `output/scripts/*.sh` |
| `cloud-init` | Generate cloud-init config | `output/cloud-init.yaml` |
| `autoinstall` | Generate user-data | `output/user-data` |
| `iso` | Build bootable ISO | ISO file |
| `clean` | Remove generated files | - |

## Dependency Graph

```
                     src/config/*.config.yaml
                               │
         ┌─────────────────────┼─────────────────────┐
         ▼                     ▼                     ▼
  src/scripts/*.tpl    src/autoinstall/       src/autoinstall/
         │             cloud-init/*.yaml.tpl  *.yaml.tpl
         │                     │                     │
         ▼                     │                     │
   render_scripts()            │                     │
   (returns dict)              │                     │
         │                     │                     │
         ├──────► scripts ─────┤                     │
         │        context      ▼                     │
         │              render_cloud_init()          │
         │              (returns dict)               │
         │                     │                     │
         │                     ├──► cloud_init ──────┤
         │                     │    context          ▼
         │                     │            render_autoinstall()
         │                     │                     │
         ▼                     ▼                     ▼
  output/scripts/*.sh   output/cloud-init.yaml   output/user-data
      (standalone)                                   │
                                                     ▼
                                                build-iso.sh
                                                     │
                                                     ▼
                                                 ISO file
```

**Context Flow:**
- `scripts` dict (filename → content) available in cloud-init and autoinstall templates
- `cloud_init` dict available in autoinstall templates
- Templates embed scripts via `{{ scripts["early-net.sh"] }}` in `bootcmd`, `runcmd`, `write_files`, etc.

## Usage

```bash
cd docs/~INSTALLATION_MEDIA

# Build everything
make

# Build specific target
make scripts
make cloud-init
make autoinstall

# Force rebuild (ignores timestamps)
make -B scripts

# Dry run (show what would be built)
make -n all

# Clean and rebuild
make clean && make all
```

## Builder Module Entry Point

The Makefile invokes the builder module via `python -m builder`:

```python
# builder/__main__.py
import argparse
from .context import BuildContext
from .renderer import render_script, render_cloud_init_to_file, render_autoinstall_to_file

def main():
    parser = argparse.ArgumentParser(prog='builder')
    subparsers = parser.add_subparsers(dest='command')

    render_parser = subparsers.add_parser('render')
    render_parser.add_argument('target', choices=['script', 'cloud-init', 'autoinstall'])
    render_parser.add_argument('input', nargs='?')
    render_parser.add_argument('-o', '--output', required=True)

    args = parser.parse_args()
    ctx = BuildContext('src/config')

    if args.target == 'script':
        render_script(ctx, args.input, args.output)
    elif args.target == 'cloud-init':
        render_cloud_init_to_file(ctx, args.output)
    elif args.target == 'autoinstall':
        render_autoinstall_to_file(ctx, args.output)

if __name__ == '__main__':
    main()
```

## Incremental Builds

Make tracks file modification times and only rebuilds targets when dependencies change:

- Editing `*.config.yaml` triggers rebuild of all outputs
- Editing `*.sh.tpl` triggers rebuild of cloud-init and autoinstall (scripts are rendered internally)
- Editing a cloud-init fragment rebuilds cloud-init and autoinstall
- Editing an autoinstall template rebuilds only autoinstall

## Output Directory Structure

```
output/
├── scripts/
│   ├── early-net.sh
│   └── net-setup.sh
├── cloud-init.yaml
└── user-data
```

## Prerequisites

- Python 3.8+
- PyYAML (`pip install pyyaml`)
- Jinja2 (`pip install jinja2`)
- GNU Make

Install dependencies:
```bash
pip install pyyaml jinja2
```
