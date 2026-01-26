# 3.4 Makefile Interface

The Makefile provides a standard interface for building deployment artifacts with proper dependency tracking.

## Makefile

```makefile
.PHONY: all clean scripts cloud-init autoinstall iso help list-fragments

# Source dependencies
CONFIGS := $(wildcard book-0-builder/config/*.yaml) $(wildcard book-*/*/config/production.yaml)
SCRIPTS := $(wildcard book-*/*/scripts/*.sh.tpl)
FRAGMENTS := $(wildcard book-*/*/fragment.yaml.tpl)
BUILD_YAMLS := $(wildcard book-*/*/build.yaml)

# Fragment selection (override via command line)
INCLUDE ?=
EXCLUDE ?=
LAYER ?=

# Default: build everything
all: scripts cloud-init autoinstall

# Help
help:
	@echo "Targets:"
	@echo "  all            - Build all artifacts (default)"
	@echo "  scripts        - Generate shell scripts"
	@echo "  cloud-init     - Generate cloud-init config"
	@echo "  autoinstall    - Generate user-data"
	@echo "  iso            - Build modified Ubuntu ISO with embedded user-data"
	@echo "  list-fragments - List available cloud-init fragments"
	@echo "  clean          - Remove generated files"
	@echo ""
	@echo "Fragment Selection (cloud-init target only):"
	@echo "  LAYER     - Include fragments up to build_layer N"
	@echo "  INCLUDE   - Include only specified fragments"
	@echo "  EXCLUDE   - Exclude specified fragments"

# List available fragments
list-fragments:
	@python3 -m builder list-fragments

# Generate shell scripts (standalone, for reference/debugging)
scripts: output/scripts/early-net.sh output/scripts/net-setup.sh output/scripts/build-iso.sh

output/scripts/%.sh: src/scripts/%.sh.tpl $(CONFIGS)
	python3 -m builder render script $< -o $@

# Generate cloud-init config (renders scripts internally)
cloud-init: output/cloud-init.yaml

output/cloud-init.yaml: $(FRAGMENTS) $(SCRIPTS) $(CONFIGS) $(BUILD_YAMLS)
ifdef LAYER
	python3 -m builder render cloud-init -o $@ --layer $(LAYER)
else
	python3 -m builder render cloud-init -o $@ $(INCLUDE) $(EXCLUDE)
endif

# Generate autoinstall user-data (renders scripts + cloud-init internally)
autoinstall: output/user-data

output/user-data: $(FRAGMENTS) $(SCRIPTS) $(CONFIGS) $(BUILD_YAMLS)
	python3 -m builder render autoinstall -o $@

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
| `LAYER` | Include fragments up to build_layer N | `3` (up to Users layer) |
| `INCLUDE` | Include only specified fragments | `-i users -i ssh` |
| `EXCLUDE` | Exclude specified fragments | `-x network` |

## Dependency Graph

```
                  book-*/*/config/*.yaml
                           │
      ┌────────────────────┼─────────────────────┐
      ▼                    ▼                     ▼
book-*/*/scripts/   book-*/*/fragment.yaml.tpl  book-*/*/build.yaml
   *.sh.tpl                │                     │
      │                    │                     │
      ▼                    │                     │
render_scripts()           │                     │
(returns dict)             │                     │
      │                    │                     │
      ├────► scripts ──────┤                     │
      │      context       ▼                     │
      │            render_cloud_init()           │
      │            (returns dict)                │
      │                    │                     │
      │                    ├──► cloud_init ──────┤
      │                    │    context          ▼
      │                    │          render_autoinstall()
      │                    │                     │
      ▼                    ▼                     ▼
output/scripts/*.sh  output/cloud-init.yaml  output/user-data
   (standalone)                                  │
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

# Build cloud-init up to a specific layer
make cloud-init LAYER=3           # Up to Users layer

# Build cloud-init excluding network fragment (useful for testing)
make cloud-init EXCLUDE="-x network"

# Build cloud-init with only specific fragments
make cloud-init INCLUDE="-i users -i ssh"

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
