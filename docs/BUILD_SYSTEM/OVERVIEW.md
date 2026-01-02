# Build System

This section covers the Jinja2-based build system for generating deployment artifacts.

## Contents

- [3.1 BuildContext](./BUILD_CONTEXT.md)
- [3.2 Jinja2 Filters](./JINJA2_FILTERS.md)
- [3.3 Render CLI](./RENDER_CLI.md)
- [3.4 Makefile Interface](./MAKEFILE_INTERFACE.md)

## Overview

The build system uses Jinja2 templating to generate shell scripts and YAML configurations from templates and configuration files. BuildContext loads `*.config.yaml` files and exposes them to templates. Custom filters handle shell quoting, password hashing, and CIDR parsing. The Makefile orchestrates builds with proper dependency tracking.
