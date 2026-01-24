# Phase 1: File Movement Plan

This document specifies exact file movements for the refactor. **No content modifications** - only move, copy, and remove operations.

---

## Legend

- `MOVE` - Move file to new location
- `COPY` - Copy file (original stays, needed in multiple places)
- `REMOVE` - Delete file (out of scope or obsolete)
- `STAY` - File remains in current location
- `MKDIR` - Create directory

---

## 1. Root Level Files

| File                   | Action | Destination                                  | Notes                      |
| ---------------------- | ------ | -------------------------------------------- | -------------------------- |
| .gitignore             | STAY   |                                              | Update in Phase 2          |
| Makefile               | STAY   |                                              | Update in Phase 2          |
| pyproject.toml         | STAY   |                                              | Update in Phase 2          |
| OVERVIEW.md            | MOVE   | book-0-builder/docs/OVERVIEW.md              |                            |
| TABLE_OF_CONTENTS.md   | REMOVE |                                              | Obsolete after restructure |
| TODO.md                | STAY   |                                              | Planning doc               |
| REFACTOR.md            | STAY   |                                              | Planning doc               |
| REFACTOR_PLANNING.md   | STAY   |                                              | Planning doc               |
| vm.config.yaml         | MOVE   | book-0-builder/config/vm.config.yaml         |                            |
| vm.config.yaml.example | MOVE   | book-0-builder/config/vm.config.yaml.example |                            |
| vm.config.ps1          | REMOVE |                                              | YAML only                  |
| vm.config.ps1.example  | REMOVE |                                              | YAML only                  |
| nul                    | REMOVE |                                              | Junk file                  |

---

## 2. Builder SDK (Python)

**Source:** `builder/`
**Destination:** `book-0-builder/builder-sdk/`

| File                 | Action | Destination                             |
| -------------------- | ------ | --------------------------------------- | --------------- |
| builder/**init**.py  | MOVE   | book-0-builder/builder-sdk/**init**.py  |
| builder/**main**.py  | MOVE   | book-0-builder/builder-sdk/**main**.py  |
| builder/artifacts.py | MOVE   | book-0-builder/builder-sdk/artifacts.py |
| builder/composer.py  | MOVE   | book-0-builder/builder-sdk/composer.py  |
| builder/context.py   | MOVE   | book-0-builder/builder-sdk/context.py   |
| builder/filters.py   | MOVE   | book-0-builder/builder-sdk/filters.py   |
| builder/renderer.py  | MOVE   | book-0-builder/builder-sdk/renderer.py  |
| builder/**pycache**/ | REMOVE |                                         | Generated files |

---

## 3. Host SDK (PowerShell)

**Source:** `tests/lib/`
**Destination:** `book-0-builder/host-sdk/`

| File                             | Action | Destination                                       |
| -------------------------------- | ------ | ------------------------------------------------- |
| tests/lib/SDK.ps1                | MOVE   | book-0-builder/host-sdk/SDK.ps1                   |
| tests/lib/Builder.ps1            | MOVE   | book-0-builder/host-sdk/modules/Builder.ps1       |
| tests/lib/Config.ps1             | MOVE   | book-0-builder/host-sdk/modules/Config.ps1        |
| tests/lib/General.ps1            | MOVE   | book-0-builder/host-sdk/modules/General.ps1       |
| tests/lib/Multipass.ps1          | MOVE   | book-0-builder/host-sdk/modules/Multipass.ps1     |
| tests/lib/Network.ps1            | MOVE   | book-0-builder/host-sdk/modules/Network.ps1       |
| tests/lib/Settings.ps1           | MOVE   | book-0-builder/host-sdk/modules/Settings.ps1      |
| tests/lib/Vbox.ps1               | MOVE   | book-0-builder/host-sdk/modules/Vbox.ps1          |
| tests/lib/Verifications.ps1      | MOVE   | book-0-builder/host-sdk/modules/Verifications.ps1 |
| tests/lib/helpers/Config.ps1     | MOVE   | book-0-builder/host-sdk/helpers/Config.ps1        |
| tests/lib/helpers/PowerShell.ps1 | MOVE   | book-0-builder/host-sdk/helpers/PowerShell.ps1    |

---

## 4. Test Scripts

**Source:** `tests/`
**Destination:** `book-0-builder/host-sdk/`

| File                             | Action | Destination                                        | Notes     |
| -------------------------------- | ------ | -------------------------------------------------- | --------- |
| tests/Invoke-AutoinstallTest.ps1 | MOVE   | book-0-builder/host-sdk/Invoke-AutoinstallTest.ps1 |           |
| tests/Invoke-IncrementalTest.ps1 | MOVE   | book-0-builder/host-sdk/Invoke-IncrementalTest.ps1 |           |
| tests/TEMP_Invoke-LefeckTest.ps1 | REMOVE |                                                    | Temp file |
| tests/TEMP_Invoke-VentoyTest.ps1 | REMOVE |                                                    | Temp file |

---

## 5. Book 1 - Foundation Layer

### 5.1 Base Autoinstall Template

| File                          | Action | Destination                                 |
| ----------------------------- | ------ | ------------------------------------------- |
| src/autoinstall/base.yaml.tpl | MOVE   | book-1-foundation/00-base/fragment.yaml.tpl |

### 5.2 Foundation Scripts

| File                         | Action | Destination                                        |
| ---------------------------- | ------ | -------------------------------------------------- |
| src/scripts/build-iso.sh.tpl | MOVE   | book-1-foundation/00-base/scripts/build-iso.sh.tpl |
| src/scripts/early-net.sh.tpl | MOVE   | book-1-foundation/00-base/scripts/early-net.sh.tpl |

### 5.3 Foundation Configs

| File                                   | Action | Destination                                                  | Notes             |
| -------------------------------------- | ------ | ------------------------------------------------------------ | ----------------- |
| src/config/storage.config.yaml         | MOVE   | book-1-foundation/00-base/config/storage.config.yaml         | Rename in Phase 2 |
| src/config/storage.config.yaml.example | MOVE   | book-1-foundation/00-base/config/storage.config.yaml.example |                   |
| src/config/image.config.yaml           | MOVE   | book-1-foundation/00-base/config/image.config.yaml           | Rename in Phase 2 |
| src/config/image.config.yaml.example   | MOVE   | book-1-foundation/00-base/config/image.config.yaml.example   |                   |
| src/config/testing.config.yaml         | MOVE   | book-1-foundation/00-base/config/testing.config.yaml         | Rename in Phase 2 |
| src/config/testing.config.yaml.example | MOVE   | book-1-foundation/00-base/config/testing.config.yaml.example |                   |

---

## 6. Book 2 - Cloud Layer Fragments

### 6.1 Cloud-init Templates

| File                                                  | Action | Destination                                      |
| ----------------------------------------------------- | ------ | ------------------------------------------------ |
| src/autoinstall/cloud-init/10-network.yaml.tpl        | MOVE   | book-2-cloud/10-network/fragment.yaml.tpl        |
| src/autoinstall/cloud-init/15-kernel.yaml.tpl         | MOVE   | book-2-cloud/15-kernel/fragment.yaml.tpl         |
| src/autoinstall/cloud-init/20-users.yaml.tpl          | MOVE   | book-2-cloud/20-users/fragment.yaml.tpl          |
| src/autoinstall/cloud-init/25-ssh.yaml.tpl            | MOVE   | book-2-cloud/25-ssh/fragment.yaml.tpl            |
| src/autoinstall/cloud-init/30-ufw.yaml.tpl            | MOVE   | book-2-cloud/30-ufw/fragment.yaml.tpl            |
| src/autoinstall/cloud-init/40-system.yaml.tpl         | MOVE   | book-2-cloud/40-system/fragment.yaml.tpl         |
| src/autoinstall/cloud-init/45-msmtp.yaml.tpl          | MOVE   | book-2-cloud/45-msmtp/fragment.yaml.tpl          |
| src/autoinstall/cloud-init/50-packages.yaml.tpl       | MOVE   | book-2-cloud/50-packages/fragment.yaml.tpl       |
| src/autoinstall/cloud-init/50-pkg-security.yaml.tpl   | MOVE   | book-2-cloud/50-pkg-security/fragment.yaml.tpl   |
| src/autoinstall/cloud-init/55-security-mon.yaml.tpl   | MOVE   | book-2-cloud/55-security-mon/fragment.yaml.tpl   |
| src/autoinstall/cloud-init/60-virtualization.yaml.tpl | MOVE   | book-2-cloud/60-virtualization/fragment.yaml.tpl |
| src/autoinstall/cloud-init/70-cockpit.yaml.tpl        | MOVE   | book-2-cloud/70-cockpit/fragment.yaml.tpl        |
| src/autoinstall/cloud-init/75-claude-code.yaml.tpl    | MOVE   | book-2-cloud/75-claude-code/fragment.yaml.tpl    |
| src/autoinstall/cloud-init/76-copilot-cli.yaml.tpl    | MOVE   | book-2-cloud/76-copilot-cli/fragment.yaml.tpl    |
| src/autoinstall/cloud-init/77-opencode.yaml.tpl       | MOVE   | book-2-cloud/77-opencode/fragment.yaml.tpl       |
| src/autoinstall/cloud-init/90-ui.yaml.tpl             | MOVE   | book-2-cloud/90-ui/fragment.yaml.tpl             |
| src/autoinstall/cloud-init/999-pkg-upgrade.yaml.tpl   | MOVE   | book-2-cloud/999-pkg-upgrade/fragment.yaml.tpl   |

### 6.2 Fragment Scripts

| File                          | Action | Destination                                      |
| ----------------------------- | ------ | ------------------------------------------------ |
| src/scripts/net-setup.sh.tpl  | MOVE   | book-2-cloud/10-network/scripts/net-setup.sh.tpl |
| src/scripts/user-setup.sh.tpl | MOVE   | book-2-cloud/20-users/scripts/user-setup.sh.tpl  |

### 6.3 Fragment Configs

| File                                             | Action | Destination                                                        | Notes             |
| ------------------------------------------------ | ------ | ------------------------------------------------------------------ | ----------------- |
| src/config/network.config.yaml                   | MOVE   | book-2-cloud/10-network/config/network.config.yaml                 | Rename in Phase 2 |
| src/config/network.config.yaml.example           | MOVE   | book-2-cloud/10-network/config/network.config.yaml.example         |                   |
| src/config/identity.config.yaml                  | MOVE   | book-2-cloud/20-users/config/identity.config.yaml                  | Rename in Phase 2 |
| src/config/identity.config.yaml.example          | MOVE   | book-2-cloud/20-users/config/identity.config.yaml.example          |                   |
| src/config/smtp.config.yaml                      | MOVE   | book-2-cloud/45-msmtp/config/smtp.config.yaml                      | Rename in Phase 2 |
| src/config/smtp.config.yaml.example              | MOVE   | book-2-cloud/45-msmtp/config/smtp.config.yaml.example              |                   |
| src/config/smtp.variant.aws.config.yaml.bak      | REMOVE |                                                                    | Backup file       |
| src/config/smtp.variant.sendgrid.config.yaml.bak | REMOVE |                                                                    | Backup file       |
| src/config/cockpit.config.yaml                   | MOVE   | book-2-cloud/70-cockpit/config/cockpit.config.yaml                 | Rename in Phase 2 |
| src/config/cockpit.config.yaml.example           | MOVE   | book-2-cloud/70-cockpit/config/cockpit.config.yaml.example         |                   |
| src/config/claude_code.config.yaml               | MOVE   | book-2-cloud/75-claude-code/config/claude_code.config.yaml         | Rename in Phase 2 |
| src/config/claude_code.config.yaml.example       | MOVE   | book-2-cloud/75-claude-code/config/claude_code.config.yaml.example |                   |
| src/config/copilot_cli.config.yaml               | MOVE   | book-2-cloud/76-copilot-cli/config/copilot_cli.config.yaml         | Rename in Phase 2 |
| src/config/copilot_cli.config.yaml.example       | MOVE   | book-2-cloud/76-copilot-cli/config/copilot_cli.config.yaml.example |                   |
| src/config/opencode.config.yaml                  | MOVE   | book-2-cloud/77-opencode/config/opencode.config.yaml               | Rename in Phase 2 |
| src/config/opencode.config.yaml.example          | MOVE   | book-2-cloud/77-opencode/config/opencode.config.yaml.example       |                   |

---

## 7. Documentation

### 7.1 OUT OF SCOPE - REMOVE

| Directory                               | Action | Reason              |
| --------------------------------------- | ------ | ------------------- |
| docs/HARDWARE_BIOS_SETUP/               | REMOVE | Physical deployment |
| docs/DEPLOYMENT_PROCESS/                | REMOVE | Physical deployment |
| docs/POST_DEPLOYMENT_VALIDATION/        | REMOVE | Post-deployment     |
| docs/CLOUD_INIT_CONFIGURATION.OLD/      | REMOVE | Obsolete            |
| docs/APPENDIX/HARDWARE_COMPATIBILITY.md | REMOVE | Physical hardware   |

### 7.2 Book 0 - Builder Docs

| File                                                   | Action | Destination                                          |
| ------------------------------------------------------ | ------ | ---------------------------------------------------- |
| docs/BUILD_SYSTEM/OVERVIEW.md                          | MOVE   | book-0-builder/docs/BUILD_SYSTEM_OVERVIEW.md         |
| docs/BUILD_SYSTEM/BUILD_CONTEXT.md                     | MOVE   | book-0-builder/docs/BUILD_CONTEXT.md                 |
| docs/BUILD_SYSTEM/JINJA2_FILTERS.md                    | MOVE   | book-0-builder/docs/JINJA2_FILTERS.md                |
| docs/BUILD_SYSTEM/MAKEFILE_INTERFACE.md                | MOVE   | book-0-builder/docs/MAKEFILE_INTERFACE.md            |
| docs/BUILD_SYSTEM/RENDER_CLI.md                        | MOVE   | book-0-builder/docs/RENDER_CLI.md                    |
| docs/OVERVIEW_ARCHITECTURE/OVERVIEW.md                 | MOVE   | book-0-builder/docs/ARCHITECTURE_OVERVIEW.md         |
| docs/OVERVIEW_ARCHITECTURE/ARCHITECTURE_BENEFITS.md    | MOVE   | book-0-builder/docs/ARCHITECTURE_BENEFITS.md         |
| docs/OVERVIEW_ARCHITECTURE/DEPLOYMENT_STRATEGY.md      | REMOVE | Deployment out of scope                              |
| docs/OVERVIEW_ARCHITECTURE/KEY_COMPONENTS.md           | MOVE   | book-0-builder/docs/KEY_COMPONENTS.md                |
| docs/TROUBLESHOOTING/OVERVIEW.md                       | MOVE   | book-0-builder/docs/TROUBLESHOOTING_OVERVIEW.md      |
| docs/TROUBLESHOOTING/COMMON_ISSUES.md                  | MOVE   | book-0-builder/docs/TROUBLESHOOTING_COMMON_ISSUES.md |
| docs/TROUBLESHOOTING/LOGS_AND_DEBUGGING.md             | MOVE   | book-0-builder/docs/TROUBLESHOOTING_LOGS.md          |
| docs/APPENDIX/OVERVIEW.md                              | MOVE   | book-0-builder/docs/APPENDIX_OVERVIEW.md             |
| docs/APPENDIX/ADDITIONAL_RESOURCES.md                  | MOVE   | book-0-builder/docs/ADDITIONAL_RESOURCES.md          |
| docs/APPENDIX/REFERENCE_FILES.md                       | MOVE   | book-0-builder/docs/REFERENCE_FILES.md               |
| docs/APPENDIX/USEFUL_COMMANDS.md                       | MOVE   | book-0-builder/docs/USEFUL_COMMANDS.md               |
| docs/TESTING_AND_VALIDATION/OVERVIEW.md                | MOVE   | book-0-builder/docs/TESTING_OVERVIEW.md              |
| docs/TESTING_AND_VALIDATION/AUTOINSTALL_TESTING.md     | MOVE   | book-0-builder/docs/AUTOINSTALL_TESTING.md           |
| docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTING.md      | MOVE   | book-0-builder/docs/CLOUD_INIT_TESTING.md            |
| docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTS/README.md | MOVE   | book-0-builder/docs/CLOUD_INIT_TESTS_README.md       |

### 7.3 Book 1 - Foundation Docs

| File                                                              | Action | Destination                                                 |
| ----------------------------------------------------------------- | ------ | ----------------------------------------------------------- |
| docs/AUTOINSTALL_MEDIA_CREATION/OVERVIEW.md                       | MOVE   | book-1-foundation/00-base/docs/OVERVIEW.md                  |
| docs/AUTOINSTALL_MEDIA_CREATION/AUTOINSTALL_CONFIGURATION.md      | MOVE   | book-1-foundation/00-base/docs/AUTOINSTALL_CONFIGURATION.md |
| docs/AUTOINSTALL_MEDIA_CREATION/DOWNLOAD_UBUNTU_ISO.md            | MOVE   | book-1-foundation/00-base/docs/DOWNLOAD_UBUNTU_ISO.md       |
| docs/AUTOINSTALL_MEDIA_CREATION/MODIFIED_ISO_METHOD.md            | MOVE   | book-1-foundation/00-base/docs/MODIFIED_ISO_METHOD.md       |
| docs/AUTOINSTALL_MEDIA_CREATION/TESTED_BOOTABLE_MEDIA_CREATION.md | MOVE   | book-1-foundation/00-base/docs/BOOTABLE_MEDIA_CREATION.md   |

### 7.4 Book 2 - Fragment Docs

| File                                                          | Action | Destination                                           |
| ------------------------------------------------------------- | ------ | ----------------------------------------------------- |
| docs/NETWORK_PLANNING/OVERVIEW.md                             | MOVE   | book-2-cloud/10-network/docs/OVERVIEW.md              |
| docs/NETWORK_PLANNING/NETWORK_INFORMATION_GATHERING.md        | MOVE   | book-2-cloud/10-network/docs/INFORMATION_GATHERING.md |
| docs/NETWORK_PLANNING/NETWORK_SCRIPTS.md                      | MOVE   | book-2-cloud/10-network/docs/SCRIPTS.md               |
| docs/NETWORK_PLANNING/NETWORK_TOPOLOGY.md                     | MOVE   | book-2-cloud/10-network/docs/TOPOLOGY.md              |
| docs/CLOUD_INIT_CONFIGURATION/OVERVIEW.md                     | MOVE   | book-2-cloud/docs/OVERVIEW.md                         |
| docs/CLOUD_INIT_CONFIGURATION/NETWORK_FRAGMENT.md             | MOVE   | book-2-cloud/10-network/docs/FRAGMENT.md              |
| docs/CLOUD_INIT_CONFIGURATION/KERNEL_HARDENING_FRAGMENT.md    | MOVE   | book-2-cloud/15-kernel/docs/FRAGMENT.md               |
| docs/CLOUD_INIT_CONFIGURATION/USERS_FRAGMENT.md               | MOVE   | book-2-cloud/20-users/docs/FRAGMENT.md                |
| docs/CLOUD_INIT_CONFIGURATION/SSH_HARDENING_FRAGMENT.md       | MOVE   | book-2-cloud/25-ssh/docs/FRAGMENT.md                  |
| docs/CLOUD_INIT_CONFIGURATION/UFW_FRAGMENT.md                 | MOVE   | book-2-cloud/30-ufw/docs/FRAGMENT.md                  |
| docs/CLOUD_INIT_CONFIGURATION/SYSTEM_SETTINGS_FRAGMENT.md     | MOVE   | book-2-cloud/40-system/docs/FRAGMENT.md               |
| docs/CLOUD_INIT_CONFIGURATION/MSMTP_FRAGMENT.md               | MOVE   | book-2-cloud/45-msmtp/docs/FRAGMENT.md                |
| docs/CLOUD_INIT_CONFIGURATION/PACKAGE_SECURITY_FRAGMENT.md    | MOVE   | book-2-cloud/50-pkg-security/docs/FRAGMENT.md         |
| docs/CLOUD_INIT_CONFIGURATION/SECURITY_MONITORING_FRAGMENT.md | MOVE   | book-2-cloud/55-security-mon/docs/FRAGMENT.md         |
| docs/CLOUD_INIT_CONFIGURATION/VIRTUALIZATION_FRAGMENT.md      | MOVE   | book-2-cloud/60-virtualization/docs/FRAGMENT.md       |
| docs/CLOUD_INIT_CONFIGURATION/COCKPIT_FRAGMENT.md             | MOVE   | book-2-cloud/70-cockpit/docs/FRAGMENT.md              |
| docs/CLOUD_INIT_CONFIGURATION/CLAUDE_CODE_FRAGMENT.md         | MOVE   | book-2-cloud/75-claude-code/docs/FRAGMENT.md          |
| docs/CLOUD_INIT_CONFIGURATION/COPILOT_CLI_FRAGMENT.md         | MOVE   | book-2-cloud/76-copilot-cli/docs/FRAGMENT.md          |
| docs/CLOUD_INIT_CONFIGURATION/OPENCODE_FRAGMENT.md            | MOVE   | book-2-cloud/77-opencode/docs/FRAGMENT.md             |
| docs/CLOUD_INIT_CONFIGURATION/UI_TOUCHES_FRAGMENT.md          | MOVE   | book-2-cloud/90-ui/docs/FRAGMENT.md                   |

### 7.5 Test Docs → Fragment Tests

| File                                                                         | Action | Destination                                                 |
| ---------------------------------------------------------------------------- | ------ | ----------------------------------------------------------- |
| docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTS/TEST_6.1_NETWORK.md             | MOVE   | book-2-cloud/10-network/tests/TEST_NETWORK.md               |
| docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTS/TEST_6.2_KERNEL_HARDENING.md    | MOVE   | book-2-cloud/15-kernel/tests/TEST_KERNEL.md                 |
| docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTS/TEST_6.3_USERS.md               | MOVE   | book-2-cloud/20-users/tests/TEST_USERS.md                   |
| docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTS/TEST_6.4_SSH_HARDENING.md       | MOVE   | book-2-cloud/25-ssh/tests/TEST_SSH.md                       |
| docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTS/TEST_6.5_UFW.md                 | MOVE   | book-2-cloud/30-ufw/tests/TEST_UFW.md                       |
| docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTS/TEST_6.6_SYSTEM_SETTINGS.md     | MOVE   | book-2-cloud/40-system/tests/TEST_SYSTEM.md                 |
| docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTS/TEST_6.7_MSMTP.md               | MOVE   | book-2-cloud/45-msmtp/tests/TEST_MSMTP.md                   |
| docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTS/TEST_6.8_PACKAGE_SECURITY.md    | MOVE   | book-2-cloud/50-pkg-security/tests/TEST_PKG_SECURITY.md     |
| docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTS/TEST_6.9_SECURITY_MONITORING.md | MOVE   | book-2-cloud/55-security-mon/tests/TEST_SECURITY_MON.md     |
| docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTS/TEST_6.10_VIRTUALIZATION.md     | MOVE   | book-2-cloud/60-virtualization/tests/TEST_VIRTUALIZATION.md |
| docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTS/TEST_6.11_COCKPIT.md            | MOVE   | book-2-cloud/70-cockpit/tests/TEST_COCKPIT.md               |
| docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTS/TEST_6.12_CLAUDE_CODE.md        | MOVE   | book-2-cloud/75-claude-code/tests/TEST_CLAUDE_CODE.md       |
| docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTS/TEST_6.13_COPILOT_CLI.md        | MOVE   | book-2-cloud/76-copilot-cli/tests/TEST_COPILOT_CLI.md       |
| docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTS/TEST_6.14_OPENCODE.md           | MOVE   | book-2-cloud/77-opencode/tests/TEST_OPENCODE.md             |
| docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTS/TEST_6.15_UI_TOUCHES.md         | MOVE   | book-2-cloud/90-ui/tests/TEST_UI.md                         |

---

## 8. Generated/Cached Files - REMOVE

| Path                                  | Action |
| ------------------------------------- | ------ |
| builder/**pycache**/                  | REMOVE |
| infrastructure_host_builder.egg-info/ | REMOVE |

---

## 9. Directory Creation Summary

Create these directories before moving files:

```
book-0-builder/
book-0-builder/config/
book-0-builder/builder-sdk/
book-0-builder/host-sdk/
book-0-builder/host-sdk/modules/
book-0-builder/host-sdk/helpers/
book-0-builder/docs/

book-1-foundation/
book-1-foundation/00-base/
book-1-foundation/00-base/config/
book-1-foundation/00-base/scripts/
book-1-foundation/00-base/docs/
book-1-foundation/00-base/tests/

book-2-cloud/
book-2-cloud/docs/
book-2-cloud/10-network/
book-2-cloud/10-network/config/
book-2-cloud/10-network/scripts/
book-2-cloud/10-network/docs/
book-2-cloud/10-network/tests/
book-2-cloud/15-kernel/
book-2-cloud/15-kernel/docs/
book-2-cloud/15-kernel/tests/
book-2-cloud/20-users/
book-2-cloud/20-users/config/
book-2-cloud/20-users/scripts/
book-2-cloud/20-users/docs/
book-2-cloud/20-users/tests/
book-2-cloud/25-ssh/
book-2-cloud/25-ssh/docs/
book-2-cloud/25-ssh/tests/
book-2-cloud/30-ufw/
book-2-cloud/30-ufw/docs/
book-2-cloud/30-ufw/tests/
book-2-cloud/40-system/
book-2-cloud/40-system/docs/
book-2-cloud/40-system/tests/
book-2-cloud/45-msmtp/
book-2-cloud/45-msmtp/config/
book-2-cloud/45-msmtp/docs/
book-2-cloud/45-msmtp/tests/
book-2-cloud/50-packages/
book-2-cloud/50-pkg-security/
book-2-cloud/50-pkg-security/docs/
book-2-cloud/50-pkg-security/tests/
book-2-cloud/55-security-mon/
book-2-cloud/55-security-mon/docs/
book-2-cloud/55-security-mon/tests/
book-2-cloud/60-virtualization/
book-2-cloud/60-virtualization/docs/
book-2-cloud/60-virtualization/tests/
book-2-cloud/70-cockpit/
book-2-cloud/70-cockpit/config/
book-2-cloud/70-cockpit/docs/
book-2-cloud/70-cockpit/tests/
book-2-cloud/75-claude-code/
book-2-cloud/75-claude-code/config/
book-2-cloud/75-claude-code/docs/
book-2-cloud/75-claude-code/tests/
book-2-cloud/76-copilot-cli/
book-2-cloud/76-copilot-cli/config/
book-2-cloud/76-copilot-cli/docs/
book-2-cloud/76-copilot-cli/tests/
book-2-cloud/77-opencode/
book-2-cloud/77-opencode/config/
book-2-cloud/77-opencode/docs/
book-2-cloud/77-opencode/tests/
book-2-cloud/90-ui/
book-2-cloud/90-ui/docs/
book-2-cloud/90-ui/tests/
book-2-cloud/999-pkg-upgrade/
```

---

## 10. Empty Directories After Cleanup

These will be empty after all moves and should be removed:

```
builder/
tests/lib/helpers/
tests/lib/
tests/
src/autoinstall/cloud-init/
src/autoinstall/
src/config/
src/scripts/
src/
docs/BUILD_SYSTEM/
docs/OVERVIEW_ARCHITECTURE/
docs/AUTOINSTALL_MEDIA_CREATION/
docs/NETWORK_PLANNING/
docs/CLOUD_INIT_CONFIGURATION/
docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTS/
docs/TESTING_AND_VALIDATION/
docs/TROUBLESHOOTING/
docs/APPENDIX/
docs/HARDWARE_BIOS_SETUP/
docs/DEPLOYMENT_PROCESS/
docs/POST_DEPLOYMENT_VALIDATION/
docs/CLOUD_INIT_CONFIGURATION.OLD/
docs/
```

---

## 11. Fragments Without Configs

These fragments don't have dedicated config files - they use shared configs or have no config:

| Fragment          | Needs Config? | Notes                                   |
| ----------------- | ------------- | --------------------------------------- |
| 15-kernel         | No            | No external config                      |
| 25-ssh            | No            | Uses identity config (Phase 2 decision) |
| 30-ufw            | No            | No external config                      |
| 40-system         | No            | No external config                      |
| 50-packages       | No            | No external config                      |
| 50-pkg-security   | No            | No external config                      |
| 55-security-mon   | No            | No external config                      |
| 60-virtualization | No            | No external config                      |
| 90-ui             | No            | No external config                      |
| 999-pkg-upgrade   | No            | No external config                      |

---

## Execution Notes

1. **Order matters**: Create directories first, then move files, then clean up empty directories
2. **Git tracking**: Use `git mv` for moves to preserve history
3. **Verify**: After each section, verify files moved correctly before proceeding
4. **Rollback**: If issues arise, `git reset --hard` can restore the previous state
