.PHONY: all clean scripts cloud-init autoinstall iso help

# Source dependencies
CONFIGS := $(wildcard src/config/*.config.yaml)
SCRIPTS := $(wildcard src/scripts/*.tpl)
CLOUD_INIT_FRAGMENTS := $(wildcard src/autoinstall/cloud-init/*.yaml.tpl)
AUTOINSTALL_TEMPLATES := $(wildcard src/autoinstall/*.yaml.tpl)

# Default: build everything
all: scripts cloud-init autoinstall

# Help
help:
	@echo "Targets:"
	@echo "  all         - Build all artifacts (default)"
	@echo "  scripts     - Generate shell scripts"
	@echo "  cloud-init  - Generate cloud-init config"
	@echo "  autoinstall - Generate user-data"
	@echo "  iso         - Build bootable ISO (requires multipass)"
	@echo "  clean       - Remove generated files"

# Generate shell scripts (standalone, for reference/debugging)
scripts: output/scripts/early-net.sh output/scripts/net-setup.sh output/scripts/build-iso.sh

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

# Build ISO (runs build script in multipass)
iso: output/user-data scripts
	@echo "Run: multipass exec iso-builder -- bash -c 'cd ~/build && ./output/scripts/build-iso.sh'"

clean:
	rm -rf output/*
