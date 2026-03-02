# Plan


### Commit 1: `book-2-cloud/ssh/fragment.yaml.tpl` - Replace deprecated ChallengeResponseAuthentication with KbdInteractiveAuthentication for OpenSSH 9.x on Ubuntu 24.04 [COMPLETE]

### book-2-cloud.ssh.fragment.yaml.fix-deprecated-directive

> **File**: `book-2-cloud/ssh/fragment.yaml.tpl`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace deprecated ChallengeResponseAuthentication with KbdInteractiveAuthentication for OpenSSH 9.x on Ubuntu 24.04

#### Diff

```diff
       PermitEmptyPasswords no
-      ChallengeResponseAuthentication no
+      KbdInteractiveAuthentication no
 
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-2-cloud/ssh/docs/FRAGMENT.md` - Update stale template path, replace ChallengeResponseAuthentication with KbdInteractiveAuthentication in code block and options table [COMPLETE]

### book-2-cloud.ssh.docs.FRAGMENT.update-fragment-docs

> **File**: `book-2-cloud/ssh/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update stale template path, replace ChallengeResponseAuthentication with KbdInteractiveAuthentication in code block and options table

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/25-ssh.yaml.tpl`
+**Template:** `book-2-cloud/ssh/fragment.yaml.tpl`
 
       PermitEmptyPasswords no
-      ChallengeResponseAuthentication no
+      KbdInteractiveAuthentication no
 
-| `ChallengeResponseAuthentication` | no | Disable keyboard-interactive auth (OTP/2FA) |
+| `KbdInteractiveAuthentication` | no | Disable keyboard-interactive auth (OTP/2FA) |
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 3: `book-2-cloud/ssh/tests/TEST_SSH.md` - Update stale template path and replace challengeresponseauthentication with kbdinteractiveauthentication in test commands [COMPLETE]

### book-2-cloud.ssh.tests.TEST_SSH.update-test-docs

> **File**: `book-2-cloud/ssh/tests/TEST_SSH.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update stale template path and replace challengeresponseauthentication with kbdinteractiveauthentication in test commands

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/25-ssh.yaml.tpl`
+**Template:** `book-2-cloud/ssh/fragment.yaml.tpl`
 
-sudo sshd -T | grep -E "^permitrootlogin|^maxauthtries|^logingracetime|^permitemptypasswords|^challengeresponseauthentication"
+sudo sshd -T | grep -E "^permitrootlogin|^maxauthtries|^logingracetime|^permitemptypasswords|^kbdinteractiveauthentication"
 
-| Challenge-response | `sudo sshd -T | grep challengeresponseauthentication` | no |
+| Kbd-interactive | `sudo sshd -T | grep kbdinteractiveauthentication` | no |
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |
