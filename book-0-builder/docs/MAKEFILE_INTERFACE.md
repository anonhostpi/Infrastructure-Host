# 3.4 Makefile Interface

The Makefile provides a standard interface for building deployment artifacts with proper dependency tracking.

## Makefile

```makefile
.PHONY: all clean scripts cloud-init autoinstall iso help list-fragments

# Source dependencies
CONFIGS := $(wildcard src/config/*.config.yaml)
SCRIPTS := $(wildcard src/scripts/*.tpl)
CLOUD_INIT_FRAGMENTS := $(wildcard src/autoinstall/cloud-init/*.yaml.tpl)
AUTOINSTALL_TEMPLATES := $(wildcard src/autoinstall/*.yaml.tpl)

# Fragment selection (override via command line)
INCLUDE ?=
EXCLUDE ?=

# Default: build everything
all: scripts cloud-init autoinstall

# Help
help:
	@echo "Targets:"
	@echo "  all            - Build all artifacts (default)"
	@echo "  scripts        - Generate shell scripts"
	@echo "  cloud-init     - Generate cloud-init config"
	@echo "  autoinstall    - Generate user-data"
	@echo "  list-fragments - List available cloud-init fragments"
	@echo "  clean          - Remove generated files"

# List available fragments
list-fragments:
	@python3 -m builder list-fragments

# Generate shell scripts (standalone, for reference/debugging)
scripts: output/scripts/early-net.sh output/scripts/net-setup.sh output/scripts/build-iso.sh

output/scripts/%.sh: src/scripts/%.sh.tpl $(CONFIGS)
	python3 -m builder render script $< -o $@

# Generate cloud-init config (renders scripts internally)
cloud-init: output/cloud-init.yaml

output/cloud-init.yaml: $(CLOUD_INIT_FRAGMENTS) $(SCRIPTS) $(CONFIGS)
	python3 -m builder render cloud-init -o $@ $(INCLUDE) $(EXCLUDE)

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
| `list-fragments` | List available cloud-init fragments | - |
| `help` | Show available targets and options | - |
| `clean` | Remove generated files | - |

## Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `INCLUDE` | Include only specified fragments | `-i 20-users -i 25-ssh` |
| `EXCLUDE` | Exclude specified fragments | `-x 10-network` |

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
# Build everything
make

# Build specific target
make scripts
make cloud-init
make autoinstall

# List available fragments
make list-fragments

# Build cloud-init excluding network fragment (useful for testing)
make cloud-init EXCLUDE="-x 10-network"

# Build cloud-init with only specific fragments
make cloud-init INCLUDE="-i 20-users -i 25-ssh"

# Force rebuild (ignores timestamps)
make -B scripts

# Dry run (show what would be built)
make -n all

# Clean and rebuild
make clean && make all
```

## Builder Module Entry Point

The Makefile invokes the builder module via `python -m builder`. See [3.3 Render CLI](RENDER_CLI.md) for full CLI documentation including fragment selection options.

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
├── user-data
└── ubuntu-autoinstall.iso    # Generated by `make iso`
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
