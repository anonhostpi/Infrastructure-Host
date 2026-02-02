# Plan


### Commit 1: `book-1-foundation/base/config/base.config.yaml.example` - Create merged base.config.yaml.example combining image and storage example configs [COMPLETE]

### book-1-foundation.base.config.base.config.yaml.add-base-config-example

> **File**: `book-1-foundation/base/config/base.config.yaml.example`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Create merged base.config.yaml.example combining image and storage example configs

#### Diff

```diff
+# Base Configuration
+# Copy to base.config.yaml and fill in your values
+# THIS FILE IS TRACKED IN GIT - base.config.yaml IS NOT
+
+image:
+  release: noble        # Ubuntu codename (noble=24.04, jammy=22.04)
+  type: live-server     # Image type
+  arch: amd64           # Architecture
+
+storage:
+  # direct = ext4, simplest option for disposable root filesystem
+  # VM storage with redundancy should use a separate ZFS pool on additional drives
+  layout: direct
+  sizing_policy: all
+  match:
+    size: largest
+    # Future: target specific NVMe slot via id_path
+    # id_path: pci-0000:01:00.0-nvme-1
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 18 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-1-foundation/base/config/image.config.yaml.example` - Remove separate image.config.yaml.example, now merged into base.config.yaml.example [COMPLETE]

### book-1-foundation.base.config.image.config.yaml.remove-image-config-example

> **File**: `book-1-foundation/base/config/image.config.yaml.example`
> **Type**: DELETED
> **Commit**: 1 of 1 for this file

#### Description

Remove separate image.config.yaml.example, now merged into base.config.yaml.example

#### Diff

```diff
-# Image Configuration
-# Copy to image.config.yaml and fill in your values
-# THIS FILE IS TRACKED IN GIT - image.config.yaml IS NOT
-
-image:
-  release: noble        # Ubuntu codename (noble=24.04, jammy=22.04)
-  type: live-server     # Image type
-  arch: amd64           # Architecture
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | deletion | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 3: `book-1-foundation/base/config/storage.config.yaml.example` - Remove separate storage.config.yaml.example, now merged into base.config.yaml.example [COMPLETE]

### book-1-foundation.base.config.storage.config.yaml.remove-storage-config-example

> **File**: `book-1-foundation/base/config/storage.config.yaml.example`
> **Type**: DELETED
> **Commit**: 1 of 1 for this file

#### Description

Remove separate storage.config.yaml.example, now merged into base.config.yaml.example

#### Diff

```diff
-# Storage Configuration
-# Copy to storage.config.yaml and fill in your values
-# THIS FILE IS TRACKED IN GIT - storage.config.yaml IS NOT
-
-storage:
-  # direct = ext4, simplest option for disposable root filesystem
-  # VM storage with redundancy should use a separate ZFS pool on additional drives
-  layout: direct
-  sizing_policy: all
-  match:
-    size: largest
-    # Future: target specific NVMe slot via id_path
-    # id_path: pci-0000:01:00.0-nvme-1
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 13 lines | PASS |
| **Rule 3: Exempt** | deletion | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |
