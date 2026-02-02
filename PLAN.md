# Plan


### Commit 1: `book-2-cloud/pkg-upgrade/docs/FRAGMENT.md` - Add FRAGMENT.md documentation for the pkg-upgrade fragment describing its purpose, template structure, and runtime behavior

### book-2-cloud.pkg-upgrade.docs.FRAGMENT.add-fragment-docs

> **File**: `book-2-cloud/pkg-upgrade/docs/FRAGMENT.md`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add FRAGMENT.md documentation for the pkg-upgrade fragment describing its purpose, template structure, and runtime behavior

#### Diff

```diff
+# 6.8 Package Upgrade Fragment
+
+**Build metadata:** layer 8, order 999, `iso_required: false`
+
+Runs `apt upgrade` as the final cloud-init step. Uses `build_order: 999` to ensure all other package installations complete first.
+
+## Overview
+
+This fragment triggers a full system upgrade after all other fragments have rendered their package installations and configurations:
+
+1. **Update package lists** - `apt-get update` to refresh available versions
+2. **Unattended upgrade** - `unattended-upgrade -v` to apply pending security updates
+3. **Package manager service** - Triggers `pkg-managers-update.service` for snap, brew, pip, npm, deno
+4. **Cache cleanup** - `apt-get clean` to free disk space
+
+## Template Structure
+
+```yaml
+runcmd:
+  - apt-get update -q
+  - unattended-upgrade -v
+  - systemctl start pkg-managers-update.service || true
+  - apt-get clean
+```
+
+## Ordering
+
+| Field | Value | Purpose |
+|-------|-------|---------|
+| `build_layer` | 8 | Included starting at layer 8 (Package Security) |
+| `build_order` | 999 | Merges last in cloud-init output |
+
+The high `build_order` ensures this fragment's `runcmd` entries appear after all other fragments, so every package is installed before the upgrade runs.
+
+## Dependencies
+
+- **Requires:** `pkg-security` (provides unattended-upgrades, pkg-managers-update service/timer)
+- **Required by:** None (this is the final package operation)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 38 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-2-cloud/pkg-upgrade/tests/16/verifications.ps1` - Add verifications.ps1 module shape with param, module wrapper, and Tests ordered dict

### book-2-cloud.pkg-upgrade.tests.16.verifications.add-verifications-shape

> **File**: `book-2-cloud/pkg-upgrade/tests/16/verifications.ps1`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add verifications.ps1 module shape with param, module wrapper, and Tests ordered dict

#### Diff

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+return (New-Module -Name "Verify.PackageUpgrade" -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot........ook-0-builderhost-sdkhelpersPowerShell.ps1"
+
+    $mod.Tests = [ordered]@{
+        # WIP
+    }
+
+    Export-ModuleMember -Function @()
+} -ArgumentList $SDK)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 13 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 3: `book-2-cloud/pkg-upgrade/tests/16/verifications.ps1` - Add test verifying apt cache is clean after pkg-upgrade runs apt-get clean

### book-2-cloud.pkg-upgrade.tests.16.verifications.add-apt-cache-test

> **File**: `book-2-cloud/pkg-upgrade/tests/16/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add test verifying apt cache is clean after pkg-upgrade runs apt-get clean

#### Diff

```diff
     $mod.Tests = [ordered]@{
-        # WIP
+        "apt cache cleaned" = {
+            param($Worker)
+            $Worker.Test("pkg-upgrade.1", "apt cache cleaned",
+                "ls /var/cache/apt/archives/*.deb 2>/dev/null | wc -l",
+                "^0$")
+        }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 7 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 4: `book-2-cloud/pkg-upgrade/tests/16/verifications.ps1` - Add test verifying upgrade completion is logged in cloud-init output

### book-2-cloud.pkg-upgrade.tests.16.verifications.add-upgrade-log-test

> **File**: `book-2-cloud/pkg-upgrade/tests/16/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add test verifying upgrade completion is logged in cloud-init output

#### Diff

```diff
         "apt cache cleaned" = {
             param($Worker)
             $Worker.Test("pkg-upgrade.1", "apt cache cleaned",
                 "ls /var/cache/apt/archives/*.deb 2>/dev/null | wc -l",
                 "^0$")
         }
+        "upgrade logged" = {
+            param($Worker)
+            $Worker.Test("pkg-upgrade.2", "upgrade logged",
+                "grep -c 'System upgrade complete' /var/log/cloud-init-output.log",
+                "^[1-9]")
+        }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |
