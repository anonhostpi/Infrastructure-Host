# Plan


### Commit 1: `book-2-cloud/network/docs/FRAGMENT.md` - Update stale template path from src/autoinstall/cloud-init/10-network.yaml.tpl to fragment.yaml.tpl [COMPLETE]

### book-2-cloud.network.docs.FRAGMENT.fix-fragment-template-path

> **File**: `book-2-cloud/network/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update stale template path from src/autoinstall/cloud-init/10-network.yaml.tpl to fragment.yaml.tpl

#### Diff

```diff
 # 6.1 Network Fragment
 
-**Template:** `src/autoinstall/cloud-init/10-network.yaml.tpl`
+**Template:** `fragment.yaml.tpl`
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-2-cloud/network/docs/FRAGMENT.md` - Update broken cross-reference links to use correct relative paths to sibling docs and book-0-builder docs [COMPLETE]

### book-2-cloud.network.docs.FRAGMENT.fix-fragment-cross-refs

> **File**: `book-2-cloud/network/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update broken cross-reference links to use correct relative paths to sibling docs and book-0-builder docs

#### Diff

```diff
-The `bootcmd` array runs the network detection script from [4.3 Network Scripts](../NETWORK_PLANNING/NETWORK_SCRIPTS.md). This script:
+The `bootcmd` array runs the network detection script from [Network Scripts](./SCRIPTS.md). This script:
 
-The script is injected via the `scripts` context (see [3.3 Render CLI](../BUILD_SYSTEM/RENDER_CLI.md)).
+The script is injected via the `scripts` context (see [Render CLI](../../../book-0-builder/docs/RENDER_CLI.md)).
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 3: `book-2-cloud/network/docs/OVERVIEW.md` - Update stale config path and fix cross-reference links to sibling docs [COMPLETE]

### book-2-cloud.network.docs.OVERVIEW.fix-overview-config-path

> **File**: `book-2-cloud/network/docs/OVERVIEW.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update stale config path and fix cross-reference links to sibling docs

#### Diff

```diff
-Proper network planning ensures your servers are correctly configured and accessible after deployment. Network configuration is defined in `src/config/network.config.yaml` and rendered into scripts via Jinja2 templates.
+Proper network planning ensures your servers are correctly configured and accessible after deployment. Network configuration is defined in `config/network.config.yaml` and rendered into scripts via Jinja2 templates.
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 4: `book-2-cloud/network/docs/OVERVIEW.md` - Fix broken cross-reference links to renamed sibling docs [COMPLETE]

### book-2-cloud.network.docs.OVERVIEW.fix-overview-links

> **File**: `book-2-cloud/network/docs/OVERVIEW.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix broken cross-reference links to renamed sibling docs

#### Diff

```diff
-- [4.1 Network Information Gathering](./NETWORK_INFORMATION_GATHERING.md)
-- [4.2 Network Topology Considerations](./NETWORK_TOPOLOGY.md)
-- [4.3 Network Scripts](./NETWORK_SCRIPTS.md)
+- [Information Gathering](./INFORMATION_GATHERING.md)
+- [Topology Considerations](./TOPOLOGY.md)
+- [Network Scripts](./SCRIPTS.md)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 5: `book-2-cloud/network/docs/INFORMATION_GATHERING.md` - Update stale config paths from src/config/ to config/ and fix broken cross-reference links [COMPLETE]

### book-2-cloud.network.docs.INFORMATION_GATHERING.fix-info-config-paths

> **File**: `book-2-cloud/network/docs/INFORMATION_GATHERING.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update stale config paths from src/config/ to config/ and fix broken cross-reference links

#### Diff

```diff
-Network configuration is stored in `src/config/network.config.yaml` (not tracked in git).
+Network configuration is stored in `config/network.config.yaml` (not tracked in git).
 
-Create `src/config/network.config.yaml` (example):
+Create `config/network.config.yaml` (example):
 
-See [3.1 BuildContext](../BUILD_SYSTEM/BUILD_CONTEXT.md) for configuration loading details.
+See [BuildContext](../../../book-0-builder/docs/BUILD_CONTEXT.md) for configuration loading details.
 
-See [3.1 BuildContext - Environment Variable Overrides](../BUILD_SYSTEM/BUILD_CONTEXT.md#environment-variable-overrides) for details.
+See [BuildContext - Environment Variable Overrides](../../../book-0-builder/docs/BUILD_CONTEXT.md#environment-variable-overrides) for details.
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 6: `book-2-cloud/network/docs/SCRIPTS.md` - Update stale paths from src/scripts/ and src/config/ to scripts/ and config/, fix Jinja2 filters cross-ref [COMPLETE]

### book-2-cloud.network.docs.SCRIPTS.fix-scripts-paths

> **File**: `book-2-cloud/network/docs/SCRIPTS.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update stale paths from src/scripts/ and src/config/ to scripts/ and config/, fix Jinja2 filters cross-ref

#### Diff

```diff
-Scripts are Jinja2 templates in `src/scripts/` that render network values from `src/config/network.config.yaml`.
+Scripts are Jinja2 templates in `scripts/` that render network values from `config/network.config.yaml`.
 
-See [3.2 Jinja2 Filters](../BUILD_SYSTEM/JINJA2_FILTERS.md) for full filter documentation.
+See [Jinja2 Filters](../../../book-0-builder/docs/JINJA2_FILTERS.md) for full filter documentation.
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 7: `book-2-cloud/network/tests/TEST_NETWORK.md` - Update stale template path and broken cross-reference link in test documentation [COMPLETE]

### book-2-cloud.network.tests.TEST_NETWORK.fix-test-doc-paths

> **File**: `book-2-cloud/network/tests/TEST_NETWORK.md`
> **Type**: MODIFIED
> **Commit**: 1 of 0 for this file

#### Description

Update stale template path and broken cross-reference link in test documentation

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/10-network.yaml.tpl`
-**Fragment Docs:** [6.1 Network Fragment](../../CLOUD_INIT_CONFIGURATION/NETWORK_FRAGMENT.md)
+**Template:** `fragment.yaml.tpl`
+**Fragment Docs:** [Network Fragment](../docs/FRAGMENT.md)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |
