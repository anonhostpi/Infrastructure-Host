# Plan


### Commit 1: `book-2-cloud/security-mon/tests/9/verifications.ps1` - Add sshd-ddos and sudo jail verification tests (6.9.4 and 6.9.5)

### book-2-cloud.security-mon.tests.9.verifications.add-ddos-sudo-tests

> **File**: `book-2-cloud/security-mon/tests/9/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add sshd-ddos and sudo jail verification tests (6.9.4 and 6.9.5)

#### Diff

```diff
         $Worker.Test("6.9.3", "SSH jail configured", "sudo fail2ban-client status", "sshd")
         }
+        "SSHD-DDoS jail configured" = {
+            param($Worker)
+            $Worker.Test("6.9.4", "SSHD-DDoS jail configured", "test -f /etc/fail2ban/jail.d/sshd-ddos.conf && echo exists", "exists")
+        }
+        "Sudo jail configured" = {
+            param($Worker)
+            $Worker.Test("6.9.5", "Sudo jail configured", "test -f /etc/fail2ban/jail.d/sudo.conf && echo exists", "exists")
+        }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-2-cloud/security-mon/tests/9/verifications.ps1` - Add recidive jail verification test (6.9.6)

### book-2-cloud.security-mon.tests.9.verifications.add-recidive-test

> **File**: `book-2-cloud/security-mon/tests/9/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add recidive jail verification test (6.9.6)

#### Diff

```diff
+        "Recidive jail configured" = {
+            param($Worker)
+            $Worker.Test("6.9.6", "Recidive jail configured", "sudo fail2ban-client status recidive 2>/dev/null && echo active || echo inactive", "active")
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 3: `book-2-cloud/security-mon/tests/9/verifications.ps1` - Add email action and libvirt logrotate verification tests (6.9.7 and 6.9.8)

### book-2-cloud.security-mon.tests.9.verifications.add-email-logrotate-tests

> **File**: `book-2-cloud/security-mon/tests/9/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add email action and libvirt logrotate verification tests (6.9.7 and 6.9.8)

#### Diff

```diff
+        "Email action configured" = {
+            param($Worker)
+            $Worker.Test("6.9.7", "Email action configured", "test -f /etc/fail2ban/action.d/msmtp-mail.conf && echo exists", "exists")
+        }
+        "Libvirt log rotation configured" = {
+            param($Worker)
+            $Worker.Test("6.9.8", "Libvirt log rotation configured", "test -f /etc/logrotate.d/libvirt && echo exists", "exists")
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |
