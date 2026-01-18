.PHONY: all clean scripts cloud-init autoinstall iso cidata-iso autoinstall-iso help list-fragments cloud-init-test

# Source dependencies
CONFIGS := $(wildcard src/config/*.config.yaml)
SCRIPTS := $(wildcard src/scripts/*.tpl)
CLOUD_INIT_FRAGMENTS := $(wildcard src/autoinstall/cloud-init/*.yaml.tpl)
AUTOINSTALL_TEMPLATES := $(wildcard src/autoinstall/*.yaml.tpl)

# Fragment selection (override via command line)
# Examples:
#   make cloud-init INCLUDE="-i 20-users -i 25-ssh"
#   make cloud-init EXCLUDE="-x 10-network"
INCLUDE ?=
EXCLUDE ?=

# Default: build everything
all: scripts cloud-init autoinstall

# Help
help:
	@echo "Targets:"
	@echo "  all            - Build all artifacts (default)"
	@echo "  scripts        - Generate shell scripts"
	@echo "  cloud-init     - Generate cloud-init config (all fragments)"
	@echo "  autoinstall    - Generate user-data"
	@echo "  iso            - Build both ISOs (cidata + autoinstall)"
	@echo "  cidata-iso     - Build CIDATA ISO only"
	@echo "  autoinstall-iso - Build autoinstall ISO only"
	@echo "  list-fragments - List available cloud-init fragments"
	@echo "  clean          - Remove generated files"
	@echo ""
	@echo "Fragment Selection (cloud-init target only):"
	@echo "  INCLUDE   - Include only specified fragments"
	@echo "  EXCLUDE   - Exclude specified fragments"
	@echo ""
	@echo "Examples:"
	@echo "  make cloud-init EXCLUDE=\"-x 10-network\""
	@echo "  make cloud-init INCLUDE=\"-i 20-users -i 25-ssh\""
	@echo "  python -m builder render cloud-init -o test.yaml -x 10-network"

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
	python3 -m builder render autoinstall -o $@

# Build ISOs (run inside multipass VM where output/ is mounted)
cidata-iso: output/user-data scripts
	bash output/scripts/build-iso.sh cidata

autoinstall-iso: scripts
	bash output/scripts/build-iso.sh autoinstall

iso: cidata-iso autoinstall-iso

clean:
	rm -rf output/*
