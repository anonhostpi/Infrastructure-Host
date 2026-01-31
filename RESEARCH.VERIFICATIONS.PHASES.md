# Verifications: Phases B, C, D

Reference: `PHASE_2/BOOK_0/INITIAL.VERIFICATIONS.md` for full design decisions.
Reference: `git show master:book-0-builder/host-sdk/modules/Verifications.ps1` for original test functions.

## Design Decisions (settled)

- All tests go through `$Worker.Exec()` — no host-side SSH
- AI CLI tests **fail** if no auth configured
- Layers 16-18 are Package Security extensions dependent on `testing: true` build config
- Host-side tests (6.4.4, 6.4.5, 6.11.7) redesigned as internal loopback via `$Worker.Exec("ssh ... localhost ...")`

---

## Phase B: Layer 7 (MSMTP) + Layer 8 (PackageSecurity)

### Layer 7: MSMTP (11 tests, ~6 commits)

**Tests 6.7.1-6.7.3: Basic installation** (~10 lines)
- 6.7.1: `which msmtp`
- 6.7.2: `test -f /etc/msmtprc`
- 6.7.3: sendmail alias exists (`test -L /usr/sbin/sendmail`)

**Test 6.7.4: Config values match SDK.Settings.SMTP** (~20 lines)
- Read msmtprc via `$Worker.Exec("sudo cat /etc/msmtprc")`
- Verify host, port, from_email, user match `$mod.SDK.Settings.SMTP`
- Early return if `$smtp.host` not configured (fork + skip)

**Tests 6.7.5-6.7.6: Provider + auth method** (~20 lines)
- 6.7.5: Provider-specific validation via switch on `$smtp.host`:
  - SendGrid: user must be "apikey"
  - AWS SES: port 587 or 465
  - Gmail: OAuth requires passwordeval
  - Proton Bridge (localhost:1025): tls_certcheck off
  - M365: port 587
- 6.7.6: Auth method validation (plain, login, OAuth, external)
- Needs `Get-SMTPProviderName` helper (private function in method body or separate scriptblock)

**Tests 6.7.7-6.7.8: TLS + credentials** (~20 lines)
- 6.7.7: TLS enabled, STARTTLS vs implicit (port 465), certcheck, client certs, trust file
- 6.7.8: Password inline vs passwordeval vs default file

**Tests 6.7.9-6.7.10: Aliases + helper** (~10 lines)
- 6.7.9: Root alias in `/etc/aliases` matches `$smtp.recipient`
- 6.7.10: `/usr/local/bin/msmtp-config` exists and executable

**Test 6.7.11: Send test email** (~15 lines)
- Conditional on password configured + recipient set
- Sends via `$Worker.Exec("echo -e 'Subject: ...' | sudo msmtp '$recipient'")`
- Verifies in msmtp log

### Layer 8: PackageSecurity (18 tests, ~3 commits)

**Tests 6.8.1-6.8.6** (~15 lines)
- 6.8.1-6.8.4: unattended-upgrades (installed, config, auto-upgrades, service)
- 6.8.5-6.8.6: apt-listchanges (installed, email config)

**Tests 6.8.7-6.8.12** (~15 lines)
- 6.8.7: apt-notify script executable
- 6.8.8: dpkg Pre/Post-Invoke hooks in 90pkg-notify
- 6.8.9: Verbose unattended-upgrades reporting
- 6.8.10-6.8.12: snap-update, snap refresh.hold, brew-update scripts

**Tests 6.8.13-6.8.18** (~15 lines)
- 6.8.13-6.8.15: pip-global-update, npm-global-update, deno-update scripts
- 6.8.16: pkg-managers-update systemd timer enabled+active
- 6.8.17: apt-notify common library exists
- 6.8.18: apt-notify-flush script exists

---

## Phase C: Layers 10-14 (Virtualization, Cockpit, AI CLIs)

### Layer 10: Virtualization (9 tests, ~3 commits)

**Tests 6.10.1-6.10.4** (~15 lines)
- 6.10.1: `which virsh` (libvirt installed)
- 6.10.2: `systemctl is-active libvirtd`
- 6.10.3: `which qemu-system-x86_64`
- 6.10.4: `sudo virsh net-list --all` (default network)

**Tests 6.10.5-6.10.7** (~15 lines)
- 6.10.5: `which multipass` (nested Multipass installed)
- 6.10.6: `systemctl is-active snap.multipass.multipassd.service`
- 6.10.7: `test -e /dev/kvm` (KVM available for nesting)

**Tests 6.10.8-6.10.9: Nested VM tests** (~20 lines)
- Conditional on KVM availability (fork if not)
- 6.10.8: Launch nested VM via `$Worker.Exec("multipass launch --name nested-test-vm ...")`
- 6.10.9: Exec in nested VM via `$Worker.Exec("multipass exec nested-test-vm -- echo nested-ok")`
- Cleanup: `$Worker.Exec("multipass delete nested-test-vm --purge")`
- If KVM unavailable: pass with skip message (host config issue, not cloud-init)

### Layer 11: Cockpit (7 tests, ~3 commits)

**Tests 6.11.1-6.11.3** (~12 lines)
- 6.11.1: `which cockpit-bridge`
- 6.11.2: `systemctl is-enabled cockpit.socket`
- 6.11.3: `dpkg -l cockpit-machines`

**Tests 6.11.4-6.11.6: Socket + web UI** (~20 lines)
- 6.11.4: Detect configured port from `/etc/systemd/system/cockpit.socket.d/listen.conf`, activate socket with curl, check with `ss -tlnp`
- 6.11.5: `curl -sk -o /dev/null -w '%{http_code}' https://localhost:$port/`
- 6.11.6: `curl -sk https://localhost:$port/ | grep -E 'login.js|login.css'`

**Test 6.11.7: Cockpit accessibility** (~10 lines)
- Original was SSH tunnel from host — redesign needed
- Since 6.11.5 already tests internal HTTP, this becomes redundant
- Options: (a) drop it, (b) test from a different internal path, (c) verify socket config allows expected access
- Recommend: verify the listen.conf restricts to 127.0.0.1 (security check)

### Layer 12: ClaudeCode (5 tests, ~2 commits)

**Tests 6.12.1-6.12.4** (~20 lines)
- 6.12.1: `which claude`
- 6.12.2: `sudo test -d /home/$username/.claude`
- 6.12.3: `sudo test -f /home/$username/.claude/settings.json`
- 6.12.4: Auth check — look for `.credentials.json` + `hasCompletedOnboarding`, or `ANTHROPIC_API_KEY` in `/etc/environment`. **Fail if neither found** (per user decision).

**Test 6.12.5: AI response** (~15 lines)
- `$Worker.Exec("sudo -u $username env HOME=/home/$username timeout 30 claude -p test")`
- Clean terminal escape codes from output
- Pass if non-empty response that does not match error/timeout patterns
- Only runs if auth found in 6.12.4

### Layer 13: CopilotCLI (5 tests, ~2 commits)

**Tests 6.13.1-6.13.4** (~20 lines)
- 6.13.1: `which copilot`
- 6.13.2: `sudo test -d /home/$username/.copilot`
- 6.13.3: `sudo test -f /home/$username/.copilot/config.json`
- 6.13.4: Auth check — `copilot_tokens` in config.json or `GH_TOKEN` in `/etc/environment`. **Fail if neither found.**

**Test 6.13.5: AI response** (~15 lines)
- `$Worker.Exec("sudo -u $username env HOME=/home/$username timeout 30 copilot --model gpt-4.1 -p test")`
- Same pattern as ClaudeCode 6.12.5

### Layer 14: OpenCode (7 tests, ~3 commits)

**Tests 6.14.1-6.14.5** (~15 lines)
- 6.14.1: `which node`
- 6.14.2: `which npm`
- 6.14.3: `which opencode`
- 6.14.4: `sudo test -d /home/$username/.config/opencode`
- 6.14.5: `sudo test -f /home/$username/.local/share/opencode/auth.json`

**Test 6.14.6: AI response** (~15 lines)
- `$Worker.Exec("sudo -u $username env HOME=/home/$username timeout 30 opencode run test")`
- Same pattern as ClaudeCode 6.12.5

**Test 6.14.7: Credential chain verification** (~20 lines)
- Host-side: read `$env:USERPROFILE\.claude\.credentials.json` for access/refresh tokens
- VM-side: `$Worker.Exec("sudo cat /home/$username/.local/share/opencode/auth.json")`
- Compare anthropic tokens match
- Check `$Worker.Exec("sudo su - $username -c 'opencode models'")` shows anthropic provider
- Logic depends on `$mod.SDK.Settings` for opencode.enabled + claude_code.enabled

---

## Phase D: Layers 16-18 (Package Security testing extensions)

### Layer 16: PackageManagerUpdates (7 tests, ~3 commits)

**Test 6.8.19: Testing mode gate** (~10 lines)
- `$Worker.Exec("source /usr/local/lib/apt-notify/common.sh && echo $TESTING_MODE")`
- If not "true": fail with message "rebuild with testing=true"
- If true: clear queue/test files before proceeding

**Tests 6.8.20-6.8.21: snap + npm** (~20 lines)
- 6.8.20: Run `sudo /usr/local/bin/snap-update`, check exit code + log
- 6.8.21: Install outdated `is-odd@2.0.0`, run `sudo /usr/local/bin/npm-global-update`, check queue for NPM_UPGRADED, cleanup

**Tests 6.8.22-6.8.24: pip + brew + deno** (~20 lines)
- 6.8.22: Install outdated `six==1.15.0`, run pip-global-update, check queue for PIP_UPGRADED
- 6.8.23: Run brew-update (conditional on brew installed)
- 6.8.24: Run deno-update (conditional on deno installed)

### Layer 17: UpdateSummary (3 tests, ~3 commits)

**Test 6.8.25: Report generation** (~15 lines)
- Clear test files
- Populate queue with test entries (INSTALLED, UPGRADED, SNAP_UPGRADED, etc.)
- Run `sudo timeout 30 /usr/local/bin/apt-notify-flush`
- Check `test -s /var/lib/apt-notify/test-report.txt`

**Test 6.8.26: Report content** (~10 lines)
- Read report file
- Verify NPM section present with is-odd upgrade (from layer 16 test)

**Test 6.8.27: AI model validation** (~20 lines)
- Read `/var/lib/apt-notify/test-ai-summary.txt`
- Determine expected CLI and model from `$mod.SDK.Settings`:
  - OpenCode > Claude Code > Copilot CLI (priority order)
  - Model from respective config, fallback to claude-haiku-4-5
- Fuzzy model match (`.` and `-` interchangeable)
- Verify "Generated by $cliName" and model match
- Needs `Test-FuzzyModelMatch` helper

### Layer 18: NotificationFlush (1 test, 1 commit)

**Test 6.8.28** (~10 lines)
- `$Worker.Exec("grep 'apt-notify-flush: complete' /var/lib/apt-notify/apt-notify.log")`
- Pass if found

---

## Estimated Totals

| Phase | Layers | Commits |
|-------|--------|---------|
| B | 7, 8 | ~9 |
| C | 10-14 | ~13 |
| D | 16-18 | ~7 |
| **Total** | | **~29** |
