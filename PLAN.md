# Plan


### Commit 1: `book-2-cloud/users/docs/FRAGMENT.md` - Update stale template path reference to new fragment location [COMPLETE]

### book-2-cloud.users.docs.FRAGMENT.update-template-path

> **File**: `book-2-cloud/users/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update stale template path reference to new fragment location

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/20-users.yaml.tpl`
+**Template:** `book-2-cloud/users/fragment.yaml.tpl`
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-2-cloud/users/docs/FRAGMENT.md` - Update config path reference from old src/ location to fragment config directory [COMPLETE]

### book-2-cloud.users.docs.FRAGMENT.update-config-path

> **File**: `book-2-cloud/users/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update config path reference from old src/ location to fragment config directory

#### Diff

```diff
-Create `src/config/identity.config.yaml`:
+Create `book-2-cloud/users/config/identity.config.yaml`:
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 3: `book-2-cloud/users/docs/FRAGMENT.md` - Replace inline template example with actual base64-script approach used by fragment.yaml.tpl [COMPLETE]

### book-2-cloud.users.docs.FRAGMENT.update-template-block

> **File**: `book-2-cloud/users/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace inline template example with actual base64-script approach used by fragment.yaml.tpl

#### Diff

```diff
 ## Template
 
 ```yaml
 bootcmd:
-  # Create admin user in bootcmd (runs early, before write_files with defer:true)
-  # This ensures the user exists when deferred write_files need to set ownership
-  # Wrapped in subshell so exit doesn't terminate the combined bootcmd script
-  # Conditional ensures this only runs once (bootcmd runs on every boot)
-  - |
-    (
-    if ! id -u {{ identity.username }} >/dev/null 2>&1; then
-      # Create user - only add to sudo group here; virtualization groups added by 60-virtualization
-      useradd -m -s /bin/bash -N -G sudo {{ identity.username }}
-      echo '{{ identity.username }}:{{ identity.password | sha512_hash }}' | chpasswd -e
-      echo '{{ identity.username }} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/{{ identity.username }}
-      chmod 440 /etc/sudoers.d/{{ identity.username }}
-{%- if identity.ssh_authorized_keys is defined and identity.ssh_authorized_keys %}
-      mkdir -p /home/{{ identity.username }}/.ssh
-      chmod 700 /home/{{ identity.username }}/.ssh
-      : > /home/{{ identity.username }}/.ssh/authorized_keys
-{%- for key in identity.ssh_authorized_keys %}
-      echo '{{ key }}' >> /home/{{ identity.username }}/.ssh/authorized_keys
-{%- endfor %}
-      chmod 600 /home/{{ identity.username }}/.ssh/authorized_keys
-      chown -R {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.ssh
-{%- endif %}
-      # Lock root account
-      passwd -l root
-    fi
-    )
+  # user-setup.sh is base64 encoded to avoid YAML multiline string parsing issues
+  # (multipass/cloud-init can mangle multi-line bootcmd scripts)
+  # Directory structure: /var/lib/cloud/scripts/user-setup/
+  #   - user-setup.sh.b64  (base64 encoded script)
+  #   - user-setup.sh      (decoded executable)
+  #   - user-setup.log     (execution output)
+  - mkdir -p /var/lib/cloud/scripts/user-setup
+  - echo '{{ scripts["user-setup.sh"] | to_base64 }}' > /var/lib/cloud/scripts/user-setup/user-setup.sh.b64
+  - base64 -d /var/lib/cloud/scripts/user-setup/user-setup.sh.b64 > /var/lib/cloud/scripts/user-setup/user-setup.sh
+  - chmod +x /var/lib/cloud/scripts/user-setup/user-setup.sh
+  - /var/lib/cloud/scripts/user-setup/user-setup.sh >> /var/lib/cloud/scripts/user-setup/user-setup.log 2>&1 || true
 
 ssh_pwauth: true
 ```
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 37 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 4: `book-2-cloud/users/docs/FRAGMENT.md` - Update rationale section to reflect base64-script approach instead of inline subshell [COMPLETE]

### book-2-cloud.users.docs.FRAGMENT.update-bootcmd-rationale

> **File**: `book-2-cloud/users/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update rationale section to reflect base64-script approach instead of inline subshell

#### Diff

```diff
 ## Why bootcmd Instead of users Directive?
 
-This fragment uses `bootcmd` instead of cloud-init's `users:` directive because:
+This fragment uses `bootcmd` with a base64-encoded helper script instead of cloud-init's `users:` directive because:
 
-1. **Early execution** - `bootcmd` runs before `write_files` with `defer: true`, ensuring the user exists when deferred files need to set ownership
-2. **Cloud provider compatibility** - The `users:` directive can conflict with cloud providers' default user setup (e.g., multipass creates an `ubuntu` user)
-3. **Idempotent** - The `if ! id -u` guard ensures the script only creates the user once, even though `bootcmd` runs on every boot
+1. **Early execution** - `bootcmd` runs before `write_files` with `defer: true`, ensuring the user exists when deferred files need to set ownership
+2. **Cloud provider compatibility** - The `users:` directive can conflict with cloud providers' default user setup (e.g., multipass creates an `ubuntu` user)
+3. **Idempotent** - The `if id -u` guard in `user-setup.sh` ensures the script only creates the user once, even though `bootcmd` runs on every boot
+4. **YAML safety** - The script is base64-encoded to avoid multiline string parsing issues with multipass/cloud-init
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 5: `book-2-cloud/users/docs/FRAGMENT.md` - Update cross-reference links to use relative paths within fragment docs [COMPLETE]

### book-2-cloud.users.docs.FRAGMENT.update-cross-refs

> **File**: `book-2-cloud/users/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update cross-reference links to use relative paths within fragment docs

#### Diff

```diff
-**Note:** SSH password authentication is enabled here but can be hardened in [6.4 SSH Hardening](./SSH_HARDENING_FRAGMENT.md).
+**Note:** SSH password authentication is enabled here but can be hardened in the SSH fragment (`book-2-cloud/ssh/`).
 
 ## Group Membership
 
 The user is initially added only to the `sudo` group. Additional groups are added by other fragments:
 
-- `libvirt`, `kvm` - Added by [6.10 Virtualization](./VIRTUALIZATION_FRAGMENT.md)
+- `libvirt`, `kvm` - Added by the virtualization fragment (`book-2-cloud/virtualization/`)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 6: `book-2-cloud/users/docs/FRAGMENT.md` - Update Jinja2 filter cross-reference to use generic pointer [COMPLETE]

### book-2-cloud.users.docs.FRAGMENT.update-filter-ref

> **File**: `book-2-cloud/users/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update Jinja2 filter cross-reference to use generic pointer

#### Diff

```diff
-See [3.2 Jinja2 Filters](../BUILD_SYSTEM/JINJA2_FILTERS.md) for filter details.
+See `book-0-builder/builder-sdk/filters.py` for filter details.
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 7: `book-2-cloud/users/tests/TEST_USERS.md` - Update stale path references in test documentation header [COMPLETE]

### book-2-cloud.users.tests.TEST_USERS.update-test-paths

> **File**: `book-2-cloud/users/tests/TEST_USERS.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update stale path references in test documentation header

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/20-users.yaml.tpl`
-**Fragment Docs:** [6.3 Users Fragment](../../CLOUD_INIT_CONFIGURATION/USERS_FRAGMENT.md)
+**Template:** `book-2-cloud/users/fragment.yaml.tpl`
+**Fragment Docs:** [6.3 Users Fragment](../docs/FRAGMENT.md)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 8: `book-2-cloud/users/tests/3/verifications.ps1` - Add home directory existence test to match TEST_USERS.md spec [COMPLETE]

### book-2-cloud.users.tests.3.verifications.add-home-dir-test

> **File**: `book-2-cloud/users/tests/3/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add home directory existence test to match TEST_USERS.md spec

#### Diff

```diff
         "user in sudo group" = {
             param($Worker)
             $Worker.Test("6.3.2", "$username in sudo group", "groups $username", "sudo")
         }
+        "user has home directory" = {
+            param($Worker)
+            $Worker.Test("6.3.2", "$username has home directory", "test -d /home/$username && echo exists", "exists")
+        }
         "Sudoers file exists" = {
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 9: `book-2-cloud/users/tests/3/verifications.ps1` - Add user-setup.log verification tests following network fragment pattern [COMPLETE]

### book-2-cloud.users.tests.3.verifications.add-log-tests

> **File**: `book-2-cloud/users/tests/3/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add user-setup.log verification tests following network fragment pattern

#### Diff

```diff
         "Root account locked" = {
             param($Worker)
             $Worker.Test("6.3.4", "Root account locked", "sudo passwd -S root", "root L")
         }
+        "user-setup.log exists" = {
+            param($Worker)
+            $Worker.Test("6.3.5", "user-setup.log exists", "test -f /var/lib/cloud/scripts/user-setup/user-setup.log", { $true })
+        }
+        "user-setup.sh executed" = {
+            param($Worker)
+            $Worker.Test("6.3.5", "user-setup.sh executed", "cat /var/lib/cloud/scripts/user-setup/user-setup.log", "user-setup:")
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
