# Plan


### Commit 1: `book-2-cloud/kernel/docs/FRAGMENT.md` - Update stale template path from old src/autoinstall layout to current fragment path [COMPLETE]

### book-2-cloud.kernel.docs.FRAGMENT.fix-template-path

> **File**: `book-2-cloud/kernel/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update stale template path from old src/autoinstall layout to current fragment path

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/15-kernel.yaml.tpl`
+**Template:** `book-2-cloud/kernel/fragment.yaml.tpl`
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-2-cloud/kernel/tests/TEST_KERNEL.md` - Update stale template path and broken cross-link to FRAGMENT.md [COMPLETE]

### book-2-cloud.kernel.tests.TEST_KERNEL.fix-test-doc-paths

> **File**: `book-2-cloud/kernel/tests/TEST_KERNEL.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update stale template path and broken cross-link to FRAGMENT.md

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/15-kernel.yaml.tpl`
-**Fragment Docs:** [6.2 Kernel Hardening Fragment](../../CLOUD_INIT_CONFIGURATION/KERNEL_HARDENING_FRAGMENT.md)
+**Template:** `book-2-cloud/kernel/fragment.yaml.tpl`
+**Fragment Docs:** [6.2 Kernel Hardening Fragment](../../docs/FRAGMENT.md)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 3: `book-2-cloud/kernel/tests/2/verifications.ps1` - Fix duplicate 6.2.2 test IDs by assigning unique IDs to each test [COMPLETE]

### book-2-cloud.kernel.tests.2.verifications.fix-duplicate-test-ids

> **File**: `book-2-cloud/kernel/tests/2/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix duplicate 6.2.2 test IDs by assigning unique IDs to each test

#### Diff

```diff
         "Reverse path filtering enabled" = {
             param($Worker)
-            $Worker.Test("6.2.2", "Reverse path filtering enabled", "sysctl net.ipv4.conf.all.rp_filter", "= 1")
+            $Worker.Test("6.2.2", "Reverse path filtering enabled", "sysctl net.ipv4.conf.all.rp_filter", "= 1")
         }
         "SYN cookies enabled" = {
             param($Worker)
-            $Worker.Test("6.2.2", "SYN cookies enabled", "sysctl net.ipv4.tcp_syncookies", "= 1")
+            $Worker.Test("6.2.3", "SYN cookies enabled", "sysctl net.ipv4.tcp_syncookies", "= 1")
         }
         "ICMP redirects disabled" = {
             param($Worker)
-            $Worker.Test("6.2.2", "ICMP redirects disabled", "sysctl net.ipv4.conf.all.accept_redirects", "= 0")
+            $Worker.Test("6.2.4", "ICMP redirects disabled", "sysctl net.ipv4.conf.all.accept_redirects", "= 0")
         }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 4: `book-2-cloud/kernel/tests/2/verifications.ps1` - Add verification test for source routing disabled (ipv4) [COMPLETE]

### book-2-cloud.kernel.tests.2.verifications.add-source-routing-test

> **File**: `book-2-cloud/kernel/tests/2/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add verification test for source routing disabled (ipv4)

#### Diff

```diff
         "ICMP redirects disabled" = {
             param($Worker)
             $Worker.Test("6.2.4", "ICMP redirects disabled", "sysctl net.ipv4.conf.all.accept_redirects", "= 0")
         }
+        "Source routing disabled" = {
+            param($Worker)
+            $Worker.Test("6.2.5", "Source routing disabled", "sysctl net.ipv4.conf.all.accept_source_route", "= 0")
+        }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 5: `book-2-cloud/kernel/tests/2/verifications.ps1` - Add verification test for martian packet logging enabled [COMPLETE]

### book-2-cloud.kernel.tests.2.verifications.add-martian-logging-test

> **File**: `book-2-cloud/kernel/tests/2/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add verification test for martian packet logging enabled

#### Diff

```diff
         "Source routing disabled" = {
             param($Worker)
             $Worker.Test("6.2.5", "Source routing disabled", "sysctl net.ipv4.conf.all.accept_source_route", "= 0")
         }
+        "Martian logging enabled" = {
+            param($Worker)
+            $Worker.Test("6.2.6", "Martian logging enabled", "sysctl net.ipv4.conf.all.log_martians", "= 1")
+        }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 6: `book-2-cloud/kernel/tests/2/verifications.ps1` - Add verification test for kernel dmesg_restrict [COMPLETE]

### book-2-cloud.kernel.tests.2.verifications.add-dmesg-restrict-test

> **File**: `book-2-cloud/kernel/tests/2/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add verification test for kernel dmesg_restrict

#### Diff

```diff
         "Martian logging enabled" = {
             param($Worker)
             $Worker.Test("6.2.6", "Martian logging enabled", "sysctl net.ipv4.conf.all.log_martians", "= 1")
         }
+        "Kernel dmesg restricted" = {
+            param($Worker)
+            $Worker.Test("6.2.7", "Kernel dmesg restricted", "sysctl kernel.dmesg_restrict", "= 1")
+        }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 7: `book-2-cloud/kernel/tests/2/verifications.ps1` - Add verification test for kernel pointer restriction [COMPLETE]

### book-2-cloud.kernel.tests.2.verifications.add-kptr-restrict-test

> **File**: `book-2-cloud/kernel/tests/2/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add verification test for kernel pointer restriction

#### Diff

```diff
         "Kernel dmesg restricted" = {
             param($Worker)
             $Worker.Test("6.2.7", "Kernel dmesg restricted", "sysctl kernel.dmesg_restrict", "= 1")
         }
+        "Kernel pointers hidden" = {
+            param($Worker)
+            $Worker.Test("6.2.8", "Kernel pointers hidden", "sysctl kernel.kptr_restrict", "= 2")
+        }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |
