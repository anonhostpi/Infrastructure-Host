# Plan


### Commit 1: `book-2-cloud/ui/fragment.yaml.tpl` - Replace neofetch with fastfetch in packages list

### book-2-cloud.ui.fragment.yaml.replace-neofetch-pkg

> **File**: `book-2-cloud/ui/fragment.yaml.tpl`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace neofetch with fastfetch in packages list

#### Diff

```diff
 packages:
-  - neofetch
+  - fastfetch
   - bat
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-2-cloud/ui/fragment.yaml.tpl` - Replace neofetch profile.d script with fastfetch equivalent

### book-2-cloud.ui.fragment.yaml.replace-neofetch-profile

> **File**: `book-2-cloud/ui/fragment.yaml.tpl`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace neofetch profile.d script with fastfetch equivalent

#### Diff

```diff
-  # Neofetch on interactive login (optional)
-  - path: /etc/profile.d/neofetch.sh
+  # Fastfetch on interactive login (optional)
+  - path: /etc/profile.d/fastfetch.sh
     permissions: '0644'
     content: |
-      # Run neofetch on interactive login
+      # Run fastfetch on interactive login
       # Uncomment to enable:
-      # if [ -t 0 ] && command -v neofetch &> /dev/null; then
-      #   neofetch
+      # if [ -t 0 ] && command -v fastfetch &> /dev/null; then
+      #   fastfetch
       # fi
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 10 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 3: `book-2-cloud/ui/tests/15/verifications.ps1` - Add CLI package installation verification tests

### book-2-cloud.ui.tests.15.verifications.add-pkg-tests

> **File**: `book-2-cloud/ui/tests/15/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add CLI package installation verification tests

#### Diff

```diff
     $mod.Tests = [ordered]@{
-        "MOTD directory exists" = {
+        "CLI packages installed" = {
             param($Worker)
-            $Worker.Test("6.15.1", "MOTD directory exists", "test -d /etc/update-motd.d", { $true })
+            $Worker.Test("6.15.1", "CLI packages installed",
+                "dpkg -l bat fd-find jq tree htop ncdu fastfetch 2>&1 | grep -c '^ii'",
+                { param($out) [int]$out -ge 7 })
         }
-        "MOTD scripts present" = {
+        "MOTD news disabled" = {
             param($Worker)
-            $Worker.Test("6.15.2", "MOTD scripts present", "ls /etc/update-motd.d/ | wc -l", { param($out) [int]$out -gt 0 })
+            $Worker.Test("6.15.2", "MOTD news disabled",
+                "grep ENABLED /etc/default/motd-news",
+                "ENABLED=0")
         }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 12 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 4a: `book-2-cloud/ui/tests/15/verifications.ps1` - Add custom MOTD scripts verification test

### book-2-cloud.ui.tests.15.verifications.add-motd-script-test

> **File**: `book-2-cloud/ui/tests/15/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 0 for this file

#### Description

Add custom MOTD scripts verification test

#### Diff

```diff
+        "Custom MOTD scripts present" = {
+            param($Worker)
+            $Worker.Test("6.15.3", "Custom MOTD scripts present",
+                "test -x /etc/update-motd.d/00-header && test -x /etc/update-motd.d/10-sysinfo && test -x /etc/update-motd.d/90-updates && echo ok",
+                "ok")
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 4b: `book-2-cloud/ui/tests/15/verifications.ps1` - Add Ubuntu default MOTD disabled verification test

### book-2-cloud.ui.tests.15.verifications.add-default-motd-test

> **File**: `book-2-cloud/ui/tests/15/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Ubuntu default MOTD disabled verification test

#### Diff

```diff
+        "Ubuntu default MOTD disabled" = {
+            param($Worker)
+            $Worker.Test("6.15.4", "Ubuntu default MOTD disabled",
+                "test ! -x /etc/update-motd.d/10-help-text && test ! -x /etc/update-motd.d/50-motd-news && echo ok",
+                "ok")
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 4c: `book-2-cloud/ui/tests/15/verifications.ps1` - Add shell aliases file verification test

### book-2-cloud.ui.tests.15.verifications.add-aliases-test

> **File**: `book-2-cloud/ui/tests/15/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add shell aliases file verification test

#### Diff

```diff
+        "Shell aliases file exists" = {
+            param($Worker)
+            $Worker.Test("6.15.5", "Shell aliases file exists",
+                "grep 'alias cat=' /etc/profile.d/aliases.sh",
+                "batcat")
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 5: `book-2-cloud/ui/docs/FRAGMENT.md` - Fix stale template path reference in docs header

### book-2-cloud.ui.docs.FRAGMENT.update-docs-header

> **File**: `book-2-cloud/ui/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix stale template path reference in docs header

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/90-ui.yaml.tpl`
+**Template:** `book-2-cloud/ui/fragment.yaml.tpl`
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 6: `book-2-cloud/ui/docs/FRAGMENT.md` - Replace neofetch with fastfetch in docs package table and template listing

### book-2-cloud.ui.docs.FRAGMENT.update-docs-neofetch-refs

> **File**: `book-2-cloud/ui/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace neofetch with fastfetch in docs package table and template listing

#### Diff

```diff
-| `neofetch` | `neofetch` | System info display |
+| `fastfetch` | `fastfetch` | System info display |

-  - neofetch
+  - fastfetch

-  # Neofetch on interactive login (optional)
-  - path: /etc/profile.d/neofetch.sh
+  # Fastfetch on interactive login (optional)
+  - path: /etc/profile.d/fastfetch.sh

-      # Run neofetch on interactive login
+      # Run fastfetch on interactive login
       # Uncomment to enable:
-      # if [ -t 0 ] && command -v neofetch &> /dev/null; then
-      #   neofetch
+      # if [ -t 0 ] && command -v fastfetch &> /dev/null; then
+      #   fastfetch
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 14 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |
