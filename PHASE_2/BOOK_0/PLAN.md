# Plan: Book 0 - Builder SDK Updates

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Discovery Docs:
  - `PHASE_2/BOOK_0/SDK.md` - Host SDK restructure
  - `PHASE_2/BOOK_0/CONFIG.md` - Config.ps1 refactoring (superseded by DEDUPE_LAYER_WORK.md)
  - `PHASE_2/BOOK_0/REVIEW.md` - Review items (WaitForSSH, VBox SSH)
  - `PHASE_2/BOOK_0/SETTINGS.md` - Settings.ps1 refactoring
  - `PHASE_2/BOOK_0/DEDUPE_LAYER_WORK.md` - build_layers architecture
  - `PHASE_2/BOOK_0/DOCS.md` - Documentation updates

---

## Overview

Update the builder-sdk to discover fragments in the new `book-*/` structure instead of hardcoded `src/` paths. The SDK should auto-discover fragments by scanning for `build.yaml` files.

---

## Files to Modify

### Commit 1: `book-0-builder/builder-sdk/renderer.py` - Add fragment discovery function [COMPLETE]

```diff
+def discover_fragments(base_dirs=None):
+    """Discover fragments by finding build.yaml files."""
+    if base_dirs is None:
+        base_dirs = ['book-1-foundation', 'book-2-cloud']
+
+    fragments = []
+    for base_dir in base_dirs:
+        for build_yaml in Path(base_dir).rglob('build.yaml'):
+            with open(build_yaml) as f:
+                meta = yaml.safe_load(f)
+            meta['_path'] = build_yaml.parent
+            fragments.append(meta)
+    return sorted(fragments, key=lambda f: f.get('build_order', 999))
```

Reason: Fragment discovery is the foundation - all other changes depend on this function existing.

---

### Commit 2: `book-0-builder/builder-sdk/renderer.py` - Update create_environment signature [COMPLETE]

```diff
-def create_environment(template_dir='src'):
+def create_environment(template_dirs=None):
     """Create Jinja2 environment with custom filters."""
+    if template_dirs is None:
+        template_dirs = ['book-1-foundation', 'book-2-cloud']
     env = Environment(
-        loader=FileSystemLoader(template_dir),
+        loader=FileSystemLoader(template_dirs),
         keep_trailing_newline=True,
     )
```

Reason: Support multiple template directories instead of single `src/` path.

---

### Commit 3: `book-0-builder/builder-sdk/renderer.py` - Update get_environment [COMPLETE]

```diff
 def get_environment():
     """Get or create the global Jinja2 environment."""
     global _env
     if _env is None:
-        _env = create_environment('src')
+        _env = create_environment()
     return _env
```

Reason: Use new multi-directory default instead of hardcoded `src/`.

---

### Commit 4: `book-0-builder/builder-sdk/renderer.py` - Update render_scripts [COMPLETE]

```diff
 def render_scripts(ctx):
-    """Render all script templates, return as dict."""
-    scripts_dir = Path('src/scripts')
+    """Render all script templates from discovered fragments."""
     scripts = {}
-
-    if not scripts_dir.exists():
-        return scripts
-
-    for tpl_path in scripts_dir.glob('*.tpl'):
-        # Keep original filename (e.g., "early-net.sh")
-        filename = tpl_path.name.removesuffix('.tpl')
-        # Use forward slashes for Jinja2 (cross-platform)
-        template_path = tpl_path.relative_to('src').as_posix()
-        rendered = render_text(ctx, template_path)
-        scripts[filename] = rendered
-
+    for fragment in discover_fragments():
+        scripts_dir = fragment['_path'] / 'scripts'
+        if not scripts_dir.exists():
+            continue
+        for tpl_path in scripts_dir.glob('*.sh.tpl'):
+            filename = tpl_path.name.removesuffix('.tpl')
+            template_path = tpl_path.as_posix()
+            rendered = render_text(ctx, template_path)
+            scripts[filename] = rendered
     return scripts
```

Reason: Find scripts within each fragment's `scripts/` directory instead of single `src/scripts/`.

---

### Commit 5: `book-0-builder/builder-sdk/renderer.py` - Update render_script path handling [COMPLETE]

```diff
 def render_script(ctx, input_path, output_path):
     """Render a script template to output file."""
-    # Handle path relative to src/
-    if input_path.startswith('src/'):
-        template_path = input_path[4:]  # Remove 'src/' prefix
-    else:
-        template_path = input_path
-
+    template_path = input_path
     result = render_text(ctx, template_path)
     artifacts.write('scripts', Path(output_path).name, output_path, content=result)
```

Reason: Remove legacy `src/` prefix handling - paths are now direct.

---

### Commit 6: `book-0-builder/builder-sdk/renderer.py` - Update get_available_fragments [COMPLETE]

```diff
 def get_available_fragments():
-    """Return list of available fragment names (without path or extension)."""
-    fragments_dir = Path('src/autoinstall/cloud-init')
-    if not fragments_dir.exists():
-        return []
-    return sorted([
-        p.name.removesuffix('.yaml.tpl')
-        for p in fragments_dir.glob('*.yaml.tpl')
-    ])
+    """Return list of available fragment names from discovered build.yaml files."""
+    return [f['name'] for f in discover_fragments()]
```

Reason: Use `build.yaml` discovery instead of scanning `src/autoinstall/cloud-init/`.

---

### Commit 7: `book-0-builder/builder-sdk/renderer.py` - Update render_cloud_init (part 1) [COMPLETE]

```diff
 def render_cloud_init(ctx, include=None, exclude=None):
     """Render and merge cloud-init fragments, return as dict.

     Args:
         ctx: Build context
         include: List of fragment names to include (default: all)
         exclude: List of fragment names to exclude (default: none)

-    Fragment names are matched without path or extension, e.g.:
-        "20-users" matches "src/autoinstall/cloud-init/20-users.yaml.tpl"
+    Fragment names are matched against the 'name' field in build.yaml.

     Raises:
         FragmentValidationError: If a fragment produces invalid YAML
     """
-    fragments_dir = Path('src/autoinstall/cloud-init')
     scripts = render_scripts(ctx)
-
     merged = {}
```

Reason: Update docstring and remove hardcoded `fragments_dir`.

---

### Commit 8: `book-0-builder/builder-sdk/renderer.py` - Update render_cloud_init (part 2) [COMPLETE]

```diff
-    if not fragments_dir.exists():
-        return merged
-
-    for tpl_path in sorted(fragments_dir.glob('*.yaml.tpl')):
-        fragment_name = tpl_path.name.removesuffix('.yaml.tpl')
+    for fragment in discover_fragments():
+        fragment_name = fragment['name']
+        tpl_path = fragment['_path'] / 'fragment.yaml.tpl'
+
+        if not tpl_path.exists():
+            continue

         # Filter by include list (if specified)
         if include is not None and fragment_name not in include:
             continue

         # Filter by exclude list (if specified)
         if exclude is not None and fragment_name in exclude:
             continue
```

Reason: Use discovered fragments and find `fragment.yaml.tpl` relative to each.

---

### Commit 9: `book-0-builder/builder-sdk/renderer.py` - Update render_cloud_init (part 3) [COMPLETE]

```diff
-        # Use forward slashes for Jinja2 (cross-platform)
-        template_path = tpl_path.relative_to('src').as_posix()
+        template_path = tpl_path.as_posix()
         rendered = render_text(ctx, template_path, scripts=scripts)
```

Reason: Remove `relative_to('src')` - use direct path.

---

### Commit 10: `book-0-builder/builder-sdk/renderer.py` - Update render_autoinstall [COMPLETE]

```diff
 def render_autoinstall(ctx):
     """Render autoinstall user-data, return as string."""
     scripts = render_scripts(ctx)
     cloud_init = render_cloud_init(ctx)

     return render_text(
         ctx,
-        'autoinstall/base.yaml.tpl',
+        'book-1-foundation/base/autoinstall.yaml.tpl',
         scripts=scripts,
         cloud_init=cloud_init,
     )
```

Reason: Update path to base autoinstall template in new location.

---

### Commit 11: `book-0-builder/host-sdk/modules/Config.ps1` - Update fragment mappings (part 1) [COMPLETE]

```diff
         $cache = @{
             Map = [ordered]@{
-                "6.1"  = @{ Fragments = @("10-network"); Name = "Network" }
-                "6.2"  = @{ Fragments = @("15-kernel"); Name = "Kernel Hardening" }
-                "6.3"  = @{ Fragments = @("20-users"); Name = "Users" }
-                "6.4"  = @{ Fragments = @("25-ssh"); Name = "SSH Hardening" }
+                "6.1"  = @{ Fragments = @("network"); Name = "Network" }
+                "6.2"  = @{ Fragments = @("kernel"); Name = "Kernel Hardening" }
+                "6.3"  = @{ Fragments = @("users"); Name = "Users" }
+                "6.4"  = @{ Fragments = @("ssh"); Name = "SSH Hardening" }
```

Reason: Fragment names no longer have numeric prefixes - use `build.yaml` names.

---

### Commit 12: `book-0-builder/host-sdk/modules/Config.ps1` - Update fragment mappings (part 2) [COMPLETE]

```diff
-                "6.5"  = @{ Fragments = @("30-ufw"); Name = "UFW Firewall" }
-                "6.6"  = @{ Fragments = @("40-system"); Name = "System Settings" }
-                "6.7"  = @{ Fragments = @("45-msmtp"); Name = "MSMTP Mail" }
-                "6.8"  = @{ Fragments = @("50-packages", "50-pkg-security", "999-pkg-upgrade"); Name = "Package Security" }
+                "6.5"  = @{ Fragments = @("ufw"); Name = "UFW Firewall" }
+                "6.6"  = @{ Fragments = @("system"); Name = "System Settings" }
+                "6.7"  = @{ Fragments = @("msmtp"); Name = "MSMTP Mail" }
+                "6.8"  = @{ Fragments = @("packages", "pkg-security", "pkg-upgrade"); Name = "Package Security" }
```

Reason: Continue updating fragment names to match `build.yaml` names.

---

### Commit 13: `book-0-builder/host-sdk/modules/Config.ps1` - Update fragment mappings (part 3) [COMPLETE]

```diff
-                "6.9"  = @{ Fragments = @("55-security-mon"); Name = "Security Monitoring" }
-                "6.10" = @{ Fragments = @("60-virtualization"); Name = "Virtualization" }
-                "6.11" = @{ Fragments = @("70-cockpit"); Name = "Cockpit" }
-                "6.12" = @{ Fragments = @("75-claude-code"); Name = "Claude Code" }
+                "6.9"  = @{ Fragments = @("security-mon"); Name = "Security Monitoring" }
+                "6.10" = @{ Fragments = @("virtualization"); Name = "Virtualization" }
+                "6.11" = @{ Fragments = @("cockpit"); Name = "Cockpit" }
+                "6.12" = @{ Fragments = @("claude-code"); Name = "Claude Code" }
```

Reason: Continue updating fragment names.

---

### Commit 14: `book-0-builder/host-sdk/modules/Config.ps1` - Update fragment mappings (part 4) [COMPLETE]

```diff
-                "6.13" = @{ Fragments = @("76-copilot-cli"); Name = "Copilot CLI" }
-                "6.14" = @{ Fragments = @("77-opencode"); Name = "OpenCode" }
-                "6.15" = @{ Fragments = @("90-ui"); Name = "UI Touches" }
-                "6.8-updates" = @{ Fragments = @("50-packages", "50-pkg-security", "999-pkg-upgrade"); Name = "Package Manager Updates" }
+                "6.13" = @{ Fragments = @("copilot-cli"); Name = "Copilot CLI" }
+                "6.14" = @{ Fragments = @("opencode"); Name = "OpenCode" }
+                "6.15" = @{ Fragments = @("ui"); Name = "UI Touches" }
+                "6.8-updates" = @{ Fragments = @("packages", "pkg-security", "pkg-upgrade"); Name = "Package Manager Updates" }
```

Reason: Continue updating fragment names.

---

### Commit 15: `book-0-builder/host-sdk/modules/Config.ps1` - Update fragment mappings (part 5) [COMPLETE]

```diff
-                "6.8-summary" = @{ Fragments = @("50-packages", "50-pkg-security", "999-pkg-upgrade"); Name = "Update Summary" }
-                "6.8-flush" = @{ Fragments = @("50-packages", "50-pkg-security", "999-pkg-upgrade"); Name = "Notification Flush" }
+                "6.8-summary" = @{ Fragments = @("packages", "pkg-security", "pkg-upgrade"); Name = "Update Summary" }
+                "6.8-flush" = @{ Fragments = @("packages", "pkg-security", "pkg-upgrade"); Name = "Notification Flush" }
             }
         }
```

Reason: Complete fragment name updates.

---

## Part 2: Host SDK (PowerShell) Updates

Reference: `PHASE_2/BOOK_0/SDK.md`

---

### Commit 16: `book-0-builder/host-sdk/SDK.ps1` - Fix module path references [COMPLETE]

```diff
-    & "$PSScriptRoot/Settings.ps1" -SDK $SDK
-    & "$PSScriptRoot/Network.ps1" -SDK $SDK
-    & "$PSScriptRoot/General.ps1" -SDK $SDK
-    & "$PSScriptRoot/Vbox.ps1" -SDK $SDK
-    & "$PSScriptRoot/Multipass.ps1" -SDK $SDK
-    & "$PSScriptRoot/Builder.ps1" -SDK $SDK
+    & "$PSScriptRoot/modules/Settings.ps1" -SDK $SDK
+    & "$PSScriptRoot/modules/Network.ps1" -SDK $SDK
+    & "$PSScriptRoot/modules/General.ps1" -SDK $SDK
+    & "$PSScriptRoot/modules/Vbox.ps1" -SDK $SDK
+    & "$PSScriptRoot/modules/Multipass.ps1" -SDK $SDK
+    & "$PSScriptRoot/modules/Builder.ps1" -SDK $SDK
```

Reason: Modules are in `modules/` subdirectory but SDK.ps1 references them at root level (bug).

---

### Commit 17: `book-0-builder/host-sdk/SDK.ps1` - Add Logger module loading [COMPLETE]

```diff
+    & "$PSScriptRoot/modules/Logger.ps1" -SDK $SDK
     & "$PSScriptRoot/modules/Settings.ps1" -SDK $SDK
```

Reason: Logger must load first so other modules can use `$SDK.Log.*`.

---

### Commit 18: Create `book-0-builder/host-sdk/modules/Logger.ps1` - module shape [COMPLETE]

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name SDK.Logger -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    . "$PSScriptRoot\..\helpers\PowerShell.ps1"
+
+    $Logger = New-Object PSObject -Property @{ Level = "Info"; Path = $null }
+
+    # Methods added in following commits
+
+    $SDK.Extend("Log", $Logger)
+    Export-ModuleMember -Function @()
+} -ArgumentList $SDK | Import-Module -Force
```

Reason: Logger module skeleton - properties and extension point.

---

### Commit 19: `book-0-builder/host-sdk/modules/Logger.ps1` - Add Write and level methods [COMPLETE]

```diff
+    Add-ScriptMethods $Logger @{
+        Write = {
+            param([string]$Message, [string]$ForegroundColor = "White", [string]$BackgroundColor = $null)
+            $params = @{ Object = $Message; ForegroundColor = $ForegroundColor }
+            if ($BackgroundColor) { $params.BackgroundColor = $BackgroundColor }
+            Write-Host @params
+        }
+        Debug = { param([string]$Message) if ($this.Level -eq "Debug") { $this.Write("[DEBUG] $Message", "Gray") } }
+        Info  = { param([string]$Message) $this.Write("[INFO] $Message", "Cyan") }
+        Warn  = { param([string]$Message) $this.Write("[WARN] $Message", "Yellow") }
+        Error = { param([string]$Message) $this.Write("[ERROR] $Message", "Red") }
+        Step  = { param([string]$Message, [int]$Current, [int]$Total) $this.Write("[$Current/$Total] $Message", "Cyan") }
+    }

     $SDK.Extend("Log", $Logger)
```

Reason: Core Write method and log level methods (insert before Extend call).

---

### Commit 20: `book-0-builder/host-sdk/modules/Logger.ps1` - Add transcript methods [COMPLETE]

```diff
+    Add-ScriptMethods $Logger @{
+        Start = {
+            param([string]$Path)
+            $this.Path = $Path
+            Start-Transcript -Path $Path -Append
+            $this.Info("Transcript started: $Path")
+        }
+        Stop = {
+            if ($this.Path) {
+                Stop-Transcript
+                $this.Info("Transcript stopped: $($this.Path)")
+                $this.Path = $null
+            }
+        }
+    }

     $SDK.Extend("Log", $Logger)
```

Reason: Transcript control methods (insert before Extend call).

---

### Commit 21: Create `book-0-builder/host-sdk/helpers/Worker.ps1` [COMPLETE]

```diff
+function Add-CommonWorkerMethods {
+    param($Worker, $SDK)
+
+    Add-ScriptMethods $Worker @{
+        Ensure = {
+            if (-not $this.Exists()) {
+                return $this.Create()
+            }
+            return $true
+        }
+    }
+}
```

Reason: Common worker helper with Ensure method. Test method added in later commit.

---

### Commit 22: `book-0-builder/host-sdk/helpers/Worker.ps1` - Add Test method signature [COMPLETE]

```diff
+        Test = {
+            param(
+                [string]$TestId,
+                [string]$Name,
+                [string]$Command,
+                [string]$ExpectedPattern
+            )
+            # Implementation in next commit
+        }
```

Reason: Test method skeleton - executes command, checks pattern, records result.

---

### Commit 23: `book-0-builder/host-sdk/helpers/Worker.ps1` - Add Test method body [COMPLETE]

```diff
         Test = {
             param(
                 [string]$TestId,
                 [string]$Name,
                 [string]$Command,
                 [string]$ExpectedPattern
             )
-            # Implementation in next commit
+
+            $SDK.Log.Debug("Running test: $Name")
+            try {
+                $result = $this.Exec($Command)
+                $pass = $result.Success -and ($result.Output -join "`n") -match $ExpectedPattern
+                $testResult = @{ Test = $TestId; Name = $Name; Pass = $pass; Output = $result.Output; Error = $result.Error }
+                $SDK.Testing.Record($testResult)
+                if ($pass) { $SDK.Log.Write("[PASS] $Name", "Green") }
+                else { $SDK.Log.Write("[FAIL] $Name", "Red"); if ($result.Error) { $SDK.Log.Error("  Error: $($result.Error)") } }
+                return $testResult
+            }
+            catch {
+                $SDK.Log.Write("[FAIL] $Name - Exception: $_", "Red")
+                $testResult = @{ Test = $TestId; Name = $Name; Pass = $false; Error = $_.ToString() }
+                $SDK.Testing.Record($testResult)
+                return $testResult
+            }
         }
```

Reason: Test method implementation - execute, record, log result.

---

### Commit 24: `book-0-builder/host-sdk/modules/Multipass.ps1` - Add Network/CloudInit properties [COMPLETE]

```diff
         Disk = {
             return $this.Rendered.Disk
         }
+        Network = {
+            return $this.Rendered.Network
+        }
+        CloudInit = {
+            return $this.Rendered.CloudInit
+        }
     }
```

Reason: Add Network and CloudInit properties to worker config.

---

### Commit 25: `book-0-builder/host-sdk/modules/Multipass.ps1` - Remove Ensure from Worker.Methods [COMPLETE]

```diff
-            Ensure = {
-                if( -not $this.Exists() ) {
-                    return $this.Create()
-                }
-                return $true
-            }
```

Reason: Ensure moves to helpers/Worker.ps1 as common method.

---

### Commit 26: `book-0-builder/host-sdk/modules/Multipass.ps1` - Call Worker helper [COMPLETE]

```diff
             Add-ScriptProperties $worker $mod.Worker.Properties
             Add-ScriptMethods $worker $mod.Worker.Methods
-
+
+            . "$PSScriptRoot\..\helpers\Worker.ps1"
+            Add-CommonWorkerMethods $worker $mod.SDK
+
             return $worker
```

Reason: Apply common worker methods (Ensure, Test) after hypervisor-specific methods.

---

### Commit 27: `book-0-builder/host-sdk/modules/Multipass.ps1` - Update Create to use CloudInit [COMPLETE]

```diff
             Create = {
                 $config = $this.Rendered
                 return $mod.SDK.Multipass.Create(
                     $this.Name,
-                    $null,
-                    $null,
+                    $config.CloudInit,
+                    $config.Network,
                     $config.CPUs,
                     $config.Memory,
                     $config.Disk
                 )
             }
```

Reason: Worker Create should use CloudInit and Network from config.

---

### Commit 28: Create `book-0-builder/host-sdk/modules/Fragments.ps1` - module shape [COMPLETE]

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name SDK.Fragments -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot\..\helpers\PowerShell.ps1"
+
+    $Fragments = New-Object PSObject
+
+    # Layers property and methods added in following commits
+
+    $SDK.Extend("Fragments", $Fragments)
+    Export-ModuleMember -Function @()
+} -ArgumentList $SDK | Import-Module -Force
```

Reason: Fragments module skeleton.

---

### Commit 29: `book-0-builder/host-sdk/modules/Fragments.ps1` - Add Layers property [COMPLETE]

```diff
+    $Fragments | Add-Member -MemberType ScriptProperty -Name Layers -Value {
+        $results = @()
+        Get-ChildItem -Path @("book-1-foundation", "book-2-cloud") -Recurse -Filter "build.yaml" |
+        ForEach-Object {
+            $meta = Get-Content $_.FullName -Raw | ConvertFrom-Yaml
+            $results += [PSCustomObject]@{
+                Name = $meta.name
+                Path = $_.DirectoryName
+                Order = $meta.build_order
+                Layer = $meta.build_layer
+                IsoRequired = $meta.iso_required
+            }
+        }
+        return $results | Sort-Object Order
+    }

     $SDK.Extend("Fragments", $Fragments)
```

Reason: Layers ScriptProperty - live getter that discovers fragments (insert before Extend).

---

### Commit 30: `book-0-builder/host-sdk/modules/Fragments.ps1` - Add query methods [COMPLETE]

```diff
+    Add-ScriptMethods $Fragments @{
+        UpTo = {
+            param([int]$Layer)
+            return $this.Layers | Where-Object { $_.Layer -le $Layer }
+        }
+        At = {
+            param([int]$Layer)
+            return $this.Layers | Where-Object { $_.Layer -eq $Layer }
+        }
+        IsoRequired = {
+            return $this.Layers | Where-Object { $_.IsoRequired }
+        }
+    }

     $SDK.Extend("Fragments", $Fragments)
```

Reason: Fragment query methods (insert before Extend).

---

### Commit 31: `book-0-builder/host-sdk/SDK.ps1` - Add Fragments module loading [COMPLETE]

```diff
     & "$PSScriptRoot/modules/Settings.ps1" -SDK $SDK
+    & "$PSScriptRoot/modules/Fragments.ps1" -SDK $SDK
     & "$PSScriptRoot/modules/Network.ps1" -SDK $SDK
```

Reason: Load Fragments module after Settings (needs ConvertFrom-Yaml).

---

### Commit 32: `book-0-builder/host-sdk/modules/Network.ps1` - Add WaitForSSH method [COMPLETE]

```diff
+        WaitForSSH = {
+            param(
+                [Parameter(Mandatory = $true)]
+                [string]$Address,
+                [int]$Port = 22,
+                [int]$TimeoutSeconds = 300
+            )
+            $timedOut = $this.UntilSSH($Address, $Port, $TimeoutSeconds)
+            if ($timedOut) {
+                throw "Timed out waiting for SSH on ${Address}:${Port}"
+            }
+            return $true
+        }
```

Reason: WaitForSSH wraps UntilSSH with timeout exception handling.

---

### Commit 33: Create `book-0-builder/host-sdk/modules/Testing.ps1` - module shape [COMPLETE]

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name SDK.Testing -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot\..\helpers\PowerShell.ps1"
+
+    $Testing = New-Object PSObject -Property @{ Results = @(); PassCount = 0; FailCount = 0 }
+
+    # Properties and methods added in following commits
+
+    $SDK.Extend("Testing", $Testing)
+    Export-ModuleMember -Function @()
+} -ArgumentList $SDK | Import-Module -Force
```

Reason: Testing module skeleton with result tracking properties.

---

### Commit 34: `book-0-builder/host-sdk/modules/Testing.ps1` - Add All property and tracking methods [COMPLETE]

```diff
+    Add-ScriptProperties $Testing @{
+        All = {
+            return $mod.SDK.Fragments.Layers | ForEach-Object { $_.Layer } | Sort-Object -Unique
+        }
+    }
+
+    Add-ScriptMethods $Testing @{
+        Reset = {
+            $this.Results = @()
+            $this.PassCount = 0
+            $this.FailCount = 0
+        }
+        Record = {
+            param([hashtable]$Result)
+            $this.Results += $Result
+            if ($Result.Pass) { $this.PassCount++ } else { $this.FailCount++ }
+        }
+    }

     $SDK.Extend("Testing", $Testing)
```

Reason: All property (live getter) and result tracking methods (insert before Extend).

---

### Commit 35: `book-0-builder/host-sdk/modules/Testing.ps1` - Add Summary method [COMPLETE]

```diff
+    Add-ScriptMethods $Testing @{
+        Summary = {
+            $mod.SDK.Log.Write("")
+            $mod.SDK.Log.Write("========================================", "Cyan")
+            $mod.SDK.Log.Write(" Test Summary", "Cyan")
+            $mod.SDK.Log.Write("========================================", "Cyan")
+            $mod.SDK.Log.Write("  Total:  $($this.PassCount + $this.FailCount)")
+            $mod.SDK.Log.Write("  Passed: $($this.PassCount)", "Green")
+            $failColor = if ($this.FailCount -gt 0) { "Red" } else { "Green" }
+            $mod.SDK.Log.Write("  Failed: $($this.FailCount)", $failColor)
+        }
+    }

     $SDK.Extend("Testing", $Testing)
```

Reason: Summary method for test results display (insert before Extend).

---

### Commit 36: `book-0-builder/host-sdk/modules/Testing.ps1` - Add layer query methods [COMPLETE]

```diff
+    Add-ScriptMethods $Testing @{
+        Fragments = {
+            param([int]$Layer)
+            return $mod.SDK.Fragments.UpTo($Layer) | ForEach-Object { $_.Name }
+        }
+        Verifications = {
+            param([int]$Layer)
+            return $mod.SDK.Fragments.At($Layer) | ForEach-Object { "Test-$($_.Name)Fragment" }
+        }
+    }

     $SDK.Extend("Testing", $Testing)
```

Reason: Layer-based fragment/verification methods (insert before Extend).

---

### Commit 37: `book-0-builder/host-sdk/SDK.ps1` - Add Testing module loading [COMPLETE]

```diff
     & "$PSScriptRoot/modules/Builder.ps1" -SDK $SDK
+    & "$PSScriptRoot/modules/Testing.ps1" -SDK $SDK
```

Reason: Load Testing module after Builder.

---

### Commit 38: `book-0-builder/host-sdk/modules/Builder.ps1` - Add Clean method (line 64) [COMPLETE]

Location: Inside existing `Add-ScriptMethods $Builder @{` block at line 64.

```diff
     Add-ScriptMethods $Builder @{
+        Clean = {
+            $make = @("cd /home/ubuntu/infra-host", "make clean") -join " && "
+            return $this.Exec($make).Success
+        }
         Flush = {
```

Reason: Add Clean method to existing Add-ScriptMethods block.

---

### Commit 39: `book-0-builder/host-sdk/modules/Builder.ps1` - Update Build method (line 85) [COMPLETE]

Location: Replace existing `Build` method in `Add-ScriptMethods $Builder @{` block.

```diff
         Build = {
-            $make = @(
-                "cd /home/ubuntu/infra-host"
-                "make all"
-            ) -join " && "
-
-            $make_result = $this.Exec($make)
-
-            return $make_result.Success
+            param([int]$Layer)
+            $this.Clean()  # Always clean before build
+            $target = if ($Layer) { "make cloud-init LAYER=$Layer" } else { "make all" }
+            $make = @("cd /home/ubuntu/infra-host", $target) -join " && "
+            return $this.Exec($make).Success
         }
```

Reason: Build accepts Layer parameter, calls Clean first.

---

### Commit 40: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add Configurator defaults (line 14) [COMPLETE]

Location: After `$mod = @{ SDK = $SDK }` and PowerShell.ps1 dot-source (around line 14).

```diff
     . "$PSScriptRoot\..\helpers\PowerShell.ps1"

+    $mod.Configurator = @{
+        Defaults = @{
+            CPUs = 2
+            Memory = 4096
+            Disk = 40960
+            SSHUser = "ubuntu"
+            SSHHost = "localhost"
+            SSHPort = 2222
+        }
+    }

     $Vbox = New-Object PSObject
```

Reason: Default configuration values for Vbox workers.

---

### Commit 41: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add Worker structure (line 16) [COMPLETE]

Location: After Configurator, before `$Vbox = New-Object PSObject`.

```diff
+    $mod.Worker = @{
+        Properties = @{
+            Rendered = {
+                $config = $this.Config
+                $defaults = if ($this.Defaults) { $this.Defaults } else { $mod.Configurator.Defaults }
+                $rendered = @{}
+                foreach ($key in $defaults.Keys) { $rendered[$key] = $defaults[$key] }
+                foreach ($key in $config.Keys) { $rendered[$key] = $config[$key] }
+                if (-not $rendered.MediumPath) {
+                    $rendered.MediumPath = "$env:TEMP\$($rendered.Name).vdi"
+                }
+                $this | Add-Member -MemberType NoteProperty -Name Rendered -Value $rendered -Force
+                return $rendered
+            }
+        }
+        Methods = @{}
+    }

     $Vbox = New-Object PSObject
```

Reason: Worker structure with Rendered property and empty Methods placeholder.

---

### Commit 42: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add Worker property accessors [COMPLETE]

Location: Inside `$mod.Worker.Properties` block.

```diff
         Properties = @{
             Rendered = { ... }
+            Name = { return $this.Rendered.Name }
+            CPUs = { return $this.Rendered.CPUs }
+            Memory = { return $this.Rendered.Memory }
+            Disk = { return $this.Rendered.Disk }
+            Network = { return $this.Rendered.Network }
+            IsoPath = { return $this.Rendered.IsoPath }
+            MediumPath = { return $this.Rendered.MediumPath }
+            SSHUser = { return $this.Rendered.SSHUser }
+            SSHHost = { return $this.Rendered.SSHHost }
+            SSHPort = { return $this.Rendered.SSHPort }
         }
```

Reason: Worker property accessors.

---

### Commit 43: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add Worker lifecycle methods [COMPLETE]

Location: Inside `$mod.Worker.Methods` block.

```diff
-        Methods = @{}
+        Methods = @{
+            Exists = { return $mod.SDK.Vbox.Exists($this.Name) }
+            Running = { return $mod.SDK.Vbox.Running($this.Name) }
+            Start = {
+                param([string]$Type = "headless")
+                return $mod.SDK.Vbox.Start($this.Name, $Type)
+            }
+            Shutdown = {
+                param([bool]$Force)
+                return $mod.SDK.Vbox.Shutdown($this.Name, $Force)
+            }
+            UntilShutdown = {
+                param([int]$TimeoutSeconds)
+                return $mod.SDK.Vbox.UntilShutdown($this.Name, $TimeoutSeconds)
+            }
+            Destroy = { return $mod.SDK.Vbox.Destroy($this.Name) }
+        }
```

Reason: Worker lifecycle methods forwarding to SDK.Vbox.

---

### Commit 44: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add Worker Create/Exec methods [COMPLETE]

Location: Inside `$mod.Worker.Methods` block, after lifecycle methods.

```diff
             Destroy = { return $mod.SDK.Vbox.Destroy($this.Name) }
+            Create = {
+                return $mod.SDK.Vbox.Create(
+                    $this.Name,
+                    $this.MediumPath,
+                    $this.IsoPath,
+                    $this.Network,
+                    "Ubuntu_64",
+                    "efi",
+                    "SATA",
+                    $this.Disk,
+                    $this.Memory,
+                    $this.CPUs
+                )
+            }
+            Exec = {
+                param([string]$Command)
+                return $mod.SDK.Network.SSH($this.SSHUser, $this.SSHHost, $this.SSHPort, $Command)
+            }
```

Reason: Worker Create and Exec methods.

---

### Commit 45: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add Worker factory (line 26) [COMPLETE]

Location: Add to existing `Add-ScriptMethods $Vbox @{` block at line 26, before Invoke method.

```diff
     Add-ScriptMethods $Vbox @{
+        Worker = {
+            param(
+                [Parameter(Mandatory = $true)]
+                [ValidateScript({ $null -ne $_.Config -and $null -ne $_.Config.IsoPath })]
+                $Base
+            )
+            $worker = If ($Base -is [System.Collections.IDictionary]) {
+                New-Object PSObject -Property $Base
+            } Else { $Base }
+
+            Add-ScriptProperties $worker $mod.Worker.Properties
+            Add-ScriptMethods $worker $mod.Worker.Methods
+
+            . "$PSScriptRoot\..\helpers\Worker.ps1"
+            Add-CommonWorkerMethods $worker $mod.SDK
+
+            return $worker
+        }
         Invoke = {
```

Reason: Worker factory method with validation (IsoPath required).

---

### Commit 46: Create `book-0-builder/host-sdk/modules/CloudInitBuild.ps1` - module shape [COMPLETE]

```diff
+param(
+    [Parameter(Mandatory = $true)]
+    $SDK
+)
+
+New-Module -Name SDK.CloudInitBuild -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+
+    . "$PSScriptRoot\..\helpers\PowerShell.ps1"
+
+    $CloudInitBuild = New-Object PSObject
+
+    # Methods added in following commits
+
+    $SDK.Extend("CloudInitBuild", $CloudInitBuild)
+    Export-ModuleMember -Function @()
+} -ArgumentList $SDK | Import-Module -Force
```

Reason: CloudInitBuild module skeleton - handles build/worker creation for cloud-init testing.

---

### Commit 47: `book-0-builder/host-sdk/modules/CloudInitBuild.ps1` - Add Build and CreateWorker [COMPLETE]

```diff
+    Add-ScriptMethods $CloudInitBuild @{
+        Build = {
+            param([int]$Layer)
+            $mod.SDK.Log.Info("Building cloud-init for layer $Layer...")
+            if (-not $mod.SDK.Builder.Build($Layer)) { throw "Failed to build cloud-init for layer $Layer" }
+            $artifacts = $mod.SDK.Builder.Artifacts
+            if (-not $artifacts -or -not $artifacts.cloud_init) { throw "No cloud-init artifact found." }
+            return $artifacts
+        }
+        CreateWorker = {
+            param([int]$Layer, [hashtable]$Overrides = @{})
+            $artifacts = $this.Build($Layer)
+            $baseConfig = $mod.SDK.Settings.Virtualization.Runner
+            $config = @{}; foreach ($k in $baseConfig.Keys) { $config[$k] = $baseConfig[$k] }
+            $config.CloudInit = "$($mod.SDK.Root())/$($artifacts.cloud_init)"
+            foreach ($k in $Overrides.Keys) { $config[$k] = $Overrides[$k] }
+            return $mod.SDK.Multipass.Worker(@{ Config = $config })
+        }
+    }

     $SDK.Extend("CloudInitBuild", $CloudInitBuild)
```

Reason: Build and CreateWorker methods (insert before Extend).

---

### Commit 48: `book-0-builder/host-sdk/modules/CloudInitBuild.ps1` - Add Cleanup [COMPLETE]

```diff
+    Add-ScriptMethods $CloudInitBuild @{
+        Cleanup = {
+            param([string]$Name)
+            if (-not $Name) { $Name = $mod.SDK.Settings.Virtualization.Runner.Name }
+            if ($mod.SDK.Multipass.Exists($Name)) { $mod.SDK.Multipass.Destroy($Name) }
+        }
+    }

     $SDK.Extend("CloudInitBuild", $CloudInitBuild)
```

Reason: Cleanup method (insert before Extend).

---

### Commit 49: Create `book-0-builder/host-sdk/modules/CloudInitTest.ps1` - module shape [COMPLETE]

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name SDK.CloudInitTest -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot\..\helpers\PowerShell.ps1"
+
+    $CloudInitTest = New-Object PSObject
+
+    # Methods added in following commit
+
+    $SDK.Extend("CloudInitTest", $CloudInitTest)
+    Export-ModuleMember -Function @()
+} -ArgumentList $SDK | Import-Module -Force
```

Reason: CloudInitTest module skeleton - uses CloudInitBuild for worker creation.

---

### Commit 50: `book-0-builder/host-sdk/modules/CloudInitTest.ps1` - Add Run method [COMPLETE]

```diff
+    Add-ScriptMethods $CloudInitTest @{
+        Run = {
+            param([int]$Layer, [hashtable]$Overrides = @{})
+            $worker = $mod.SDK.CloudInitBuild.CreateWorker($Layer, $Overrides)
+            $mod.SDK.Log.Info("Setting up cloud-init test worker: $($worker.Name)")
+            $worker.Setup($true)
+            $mod.SDK.Testing.Reset()
+            foreach ($l in 1..$Layer) {
+                foreach ($f in $mod.SDK.Fragments.At($l)) {
+                    $worker.Test($f.Name, "Test $($f.Name)", $f.TestCommand, $f.ExpectedPattern)
+                }
+            }
+            $mod.SDK.Testing.Summary()
+            return @{ Success = ($mod.SDK.Testing.FailCount -eq 0); Results = $mod.SDK.Testing.Results; WorkerName = $worker.Name }
+        }
+    }

     $SDK.Extend("CloudInitTest", $CloudInitTest)
```

Reason: Run method - create worker via CloudInitBuild, execute tests (insert before Extend).

---

### Commit 51: Create `book-0-builder/host-sdk/modules/AutoinstallBuild.ps1` - module shape [COMPLETE]

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name SDK.AutoinstallBuild -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot\..\helpers\PowerShell.ps1"
+
+    $AutoinstallBuild = New-Object PSObject
+
+    # Methods added in following commits
+
+    $SDK.Extend("AutoinstallBuild", $AutoinstallBuild)
+    Export-ModuleMember -Function @()
+} -ArgumentList $SDK | Import-Module -Force
```

Reason: AutoinstallBuild module skeleton - handles build/worker creation for autoinstall testing.

---

### Commit 52: `book-0-builder/host-sdk/modules/AutoinstallBuild.ps1` - Add GetArtifacts and CreateWorker [COMPLETE]

```diff
+    Add-ScriptMethods $AutoinstallBuild @{
+        GetArtifacts = {
+            $artifacts = $mod.SDK.Builder.Artifacts
+            if (-not $artifacts -or -not $artifacts.iso) { throw "No ISO artifact found. Build the ISO first." }
+            return $artifacts
+        }
+        CreateWorker = {
+            param([hashtable]$Overrides = @{})
+            $artifacts = $this.GetArtifacts()
+            $baseConfig = $mod.SDK.Settings.Virtualization.Vbox
+            $config = @{}; foreach ($k in $baseConfig.Keys) { $config[$k] = $baseConfig[$k] }
+            $config.IsoPath = $artifacts.iso
+            if ($config.disk_size) { $config.Disk = $config.disk_size; $config.Remove("disk_size") }
+            foreach ($k in $Overrides.Keys) { $config[$k] = $Overrides[$k] }
+            return $mod.SDK.Vbox.Worker(@{ Config = $config })
+        }
+    }

     $SDK.Extend("AutoinstallBuild", $AutoinstallBuild)
```

Reason: GetArtifacts and CreateWorker methods (insert before Extend).

---

### Commit 53: `book-0-builder/host-sdk/modules/AutoinstallBuild.ps1` - Add Cleanup [COMPLETE]

```diff
+    Add-ScriptMethods $AutoinstallBuild @{
+        Cleanup = {
+            param([string]$Name)
+            if (-not $Name) { $Name = $mod.SDK.Settings.Virtualization.Vbox.Name }
+            if ($mod.SDK.Vbox.Exists($Name)) { $mod.SDK.Vbox.Destroy($Name) }
+        }
+    }

     $SDK.Extend("AutoinstallBuild", $AutoinstallBuild)
```

Reason: Cleanup method (insert before Extend).

---

### Commit 54: Create `book-0-builder/host-sdk/modules/AutoinstallTest.ps1` - module shape [COMPLETE]

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name SDK.AutoinstallTest -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot\..\helpers\PowerShell.ps1"
+
+    $AutoinstallTest = New-Object PSObject
+
+    # Methods added in following commit
+
+    $SDK.Extend("AutoinstallTest", $AutoinstallTest)
+    Export-ModuleMember -Function @()
+} -ArgumentList $SDK | Import-Module -Force
```

Reason: AutoinstallTest module skeleton - uses AutoinstallBuild for worker creation.

---

### Commit 55: `book-0-builder/host-sdk/modules/AutoinstallTest.ps1` - Add Run method [COMPLETE]

```diff
+    Add-ScriptMethods $AutoinstallTest @{
+        Run = {
+            param([hashtable]$Overrides = @{})
+            $worker = $mod.SDK.AutoinstallBuild.CreateWorker($Overrides)
+            $mod.SDK.Log.Info("Setting up autoinstall test worker: $($worker.Name)")
+            $worker.Ensure(); $worker.Start()
+            $mod.SDK.Log.Info("Waiting for SSH availability...")
+            $mod.SDK.Network.WaitForSSH($worker.SSHHost, $worker.SSHPort, 600)
+            $mod.SDK.Testing.Reset()
+            foreach ($f in $mod.SDK.Fragments.IsoRequired()) {
+                $worker.Test($f.Name, "Test $($f.Name)", $f.TestCommand, $f.ExpectedPattern)
+            }
+            $mod.SDK.Testing.Summary()
+            return @{ Success = ($mod.SDK.Testing.FailCount -eq 0); Results = $mod.SDK.Testing.Results; WorkerName = $worker.Name }
+        }
+    }

     $SDK.Extend("AutoinstallTest", $AutoinstallTest)
```

Reason: Run method - create worker via AutoinstallBuild, execute tests (insert before Extend).

---

### Commit 56: `book-0-builder/host-sdk/SDK.ps1` - Add build/test module loading [COMPLETE]

```diff
     & "$PSScriptRoot/modules/Testing.ps1" -SDK $SDK
+    & "$PSScriptRoot/modules/CloudInitBuild.ps1" -SDK $SDK
+    & "$PSScriptRoot/modules/CloudInitTest.ps1" -SDK $SDK
+    & "$PSScriptRoot/modules/AutoinstallBuild.ps1" -SDK $SDK
+    & "$PSScriptRoot/modules/AutoinstallTest.ps1" -SDK $SDK
```

Reason: Load build modules before test modules (test modules depend on build modules).

---

## Dependencies

This plan depends on:
- All fragments having `build.yaml` files created (handled by BOOK_1 and BOOK_2 plans)

This plan blocks:
- All fragment plans (fragments cannot be built until SDK discovers them correctly)

---

## Validation

After all commits:

**Host (PowerShell):**
- [ ] `. SDK.ps1 -Globalize` loads without errors
- [ ] `$SDK.Log.Info("test")` outputs colored text
- [ ] `$SDK.Fragments.Layers` returns fragment list
- [ ] `$SDK.Testing.All` returns layer numbers
- [ ] `$SDK.CloudInitBuild` exists (build logic reusable)
- [ ] `$SDK.AutoinstallBuild` exists (build logic reusable)

**Builder VM** (via `$SDK.Builder.Stage()` then `$SDK.Builder.Exec()`):
- [ ] `python -m builder --list` shows discovered fragments
- [ ] `make cloud-init` succeeds
- [ ] `make all` succeeds

---

## Code Review Changes (Review #1)

Reference: `PHASE_2/BOOK_0/CONFIG.md`, `PHASE_2/BOOK_0/REVIEW.md`, `PHASE_2/BOOK_0/DEDUPE_LAYER_WORK.md`

---

### Makefile Updates

---

### Commit 57: `Makefile` - Update source dependencies to book-* paths

```diff
 # Source dependencies
-CONFIGS := $(wildcard src/config/*.config.yaml)
-SCRIPTS := $(wildcard src/scripts/*.tpl)
-CLOUD_INIT_FRAGMENTS := $(wildcard src/autoinstall/cloud-init/*.yaml.tpl)
-AUTOINSTALL_TEMPLATES := $(wildcard src/autoinstall/*.yaml.tpl)
+CONFIGS := $(wildcard book-0-builder/config/*.yaml) $(wildcard book-*/*/config/production.yaml)
+SCRIPTS := $(wildcard book-*/*/scripts/*.sh.tpl)
+FRAGMENTS := $(wildcard book-*/*/fragment.yaml.tpl)
+BUILD_YAMLS := $(wildcard book-*/*/build.yaml)
```

Reason: Update paths to new book-* structure.

---

### Commit 58: `Makefile` - Add LAYER parameter

```diff
 # Fragment selection (override via command line)
 INCLUDE ?=
 EXCLUDE ?=
+LAYER ?=
```

Reason: Add LAYER parameter for build_layer filtering.

---

### Commit 59: `Makefile` - Update cloud-init target with LAYER support

```diff
 # Generate cloud-init config (renders scripts internally)
 cloud-init: output/cloud-init.yaml

-output/cloud-init.yaml: $(CLOUD_INIT_FRAGMENTS) $(SCRIPTS) $(CONFIGS)
+output/cloud-init.yaml: $(FRAGMENTS) $(SCRIPTS) $(CONFIGS) $(BUILD_YAMLS)
+ifdef LAYER
+	python3 -m builder render cloud-init -o $@ --layer $(LAYER)
+else
 	python3 -m builder render cloud-init -o $@ $(INCLUDE) $(EXCLUDE)
+endif
```

Reason: Support LAYER parameter to filter by build_layer.

---

### Commit 60: `Makefile` - Update autoinstall target dependencies

```diff
-output/user-data: $(AUTOINSTALL_TEMPLATES) $(CLOUD_INIT_FRAGMENTS) $(SCRIPTS) $(CONFIGS)
+output/user-data: $(FRAGMENTS) $(SCRIPTS) $(CONFIGS) $(BUILD_YAMLS)
 	python3 -m builder render autoinstall -o $@
```

Reason: Use new dependency variables.

---

### Commit 61: `Makefile` - Update scripts target

```diff
-# Generate shell scripts (standalone, for reference/debugging)
-scripts: output/scripts/early-net.sh output/scripts/net-setup.sh output/scripts/build-iso.sh
-
-output/scripts/%.sh: src/scripts/%.sh.tpl $(CONFIGS)
-	python3 -m builder render script $< -o $@
+# Generate shell scripts
+scripts: $(SCRIPTS) $(CONFIGS)
+	python3 -m builder render scripts -o output/scripts/
```

Reason: Use builder CLI to render all scripts from discovered fragments.

---

### Commit 62: `Makefile` - Update help text

```diff
 help:
 	@echo "Targets:"
 	@echo "  all            - Build all artifacts (default)"
 	@echo "  scripts        - Generate shell scripts"
-	@echo "  cloud-init     - Generate cloud-init config (all fragments)"
+	@echo "  cloud-init     - Generate cloud-init config"
 	@echo "  autoinstall    - Generate user-data"
 	@echo "  iso            - Build modified Ubuntu ISO with embedded user-data"
 	@echo "  list-fragments - List available cloud-init fragments"
 	@echo "  clean          - Remove generated files"
 	@echo ""
 	@echo "Fragment Selection (cloud-init target only):"
+	@echo "  LAYER     - Include fragments up to build_layer N"
 	@echo "  INCLUDE   - Include only specified fragments"
 	@echo "  EXCLUDE   - Exclude specified fragments"
 	@echo ""
 	@echo "Examples:"
-	@echo "  make cloud-init EXCLUDE=\"-x 10-network\""
-	@echo "  make cloud-init INCLUDE=\"-i 20-users -i 25-ssh\""
-	@echo "  python -m builder render cloud-init -o test.yaml -x 10-network"
+	@echo "  make cloud-init LAYER=3           # Up to Users layer"
+	@echo "  make cloud-init EXCLUDE=\"-x network\""
+	@echo "  make cloud-init INCLUDE=\"-i users -i ssh\""
```

Reason: Update help with LAYER parameter and new fragment names.

---

### Python --layer Support

---

### Commit 63: `book-0-builder/builder-sdk/__main__.py` - Add --layer argument

```diff
     cloud_init_parser.add_argument('-i', '--include', action='append', default=[])
     cloud_init_parser.add_argument('-x', '--exclude', action='append', default=[])
+    cloud_init_parser.add_argument('--layer', type=int, help='Include fragments up to this build_layer')
```

Reason: Add --layer CLI argument to cloud-init subcommand.

---

### Commit 64: `book-0-builder/builder-sdk/renderer.py` - Add layer filtering to render_cloud_init

```diff
-def render_cloud_init(ctx, include=None, exclude=None):
+def render_cloud_init(ctx, include=None, exclude=None, layer=None):
     """Render and merge cloud-init fragments, return as dict.

     Args:
         ctx: Build context
         include: List of fragment names to include (default: all)
         exclude: List of fragment names to exclude (default: none)
+        layer: If set, only include fragments with build_layer <= layer
     """
     scripts = render_scripts(ctx)
     merged = {}

     for fragment in discover_fragments():
         fragment_name = fragment['name']
+
+        # Filter by layer if specified
+        if layer is not None and fragment.get('build_layer', 999) > layer:
+            continue
+
         tpl_path = fragment['_path'] / 'fragment.yaml.tpl'
```

Reason: Filter fragments by build_layer when --layer is specified.

---

### Commit 65: `book-0-builder/builder-sdk/__main__.py` - Pass layer to render_cloud_init

```diff
     if args.command == 'cloud-init':
-        result = render_cloud_init(ctx, include=args.include, exclude=args.exclude)
+        result = render_cloud_init(ctx, include=args.include, exclude=args.exclude, layer=args.layer)
```

Reason: Pass --layer argument to render function.

---

### Builder Module - build_layers.yaml

---

### Commit 66: Create `book-0-builder/config/build_layers.yaml`

```yaml
# Build layer definitions
# Shared by build logic (Makefile LAYER=) and testing (layer names)
# build_layer in build.yaml is single source of truth for fragment ordering

layers:
  0: Base
  1: Network
  2: Kernel Hardening
  3: Users
  4: SSH Hardening
  5: UFW Firewall
  6: System Settings
  7: MSMTP Mail
  8: Package Security
  9: Security Monitoring
  10: Virtualization
  11: Cockpit
  12: Claude Code
  13: Copilot CLI
  14: OpenCode
  15: UI Touches

# Agent-dependent test levels (higher layers, reuse layer 8 fragments)
agent_dependent:
  16:
    name: Package Manager Updates
    fragments: [packages, pkg-security, pkg-upgrade]
  17:
    name: Update Summary
    fragments: [packages, pkg-security, pkg-upgrade]
  18:
    name: Notification Flush
    fragments: [packages, pkg-security, pkg-upgrade]
```

Reason: Layer-to-name mapping for build and test systems. Agent-dependent levels specify fragment overrides.

---

### Commit 67: `book-0-builder/host-sdk/modules/Builder.ps1` - Load build_layers.yaml

```diff
     $mod = @{ SDK = $SDK }
     . "$PSScriptRoot\..\helpers\PowerShell.ps1"
+
+    # Load build layers config
+    $layersPath = "$PSScriptRoot\..\..\config\build_layers.yaml"
+    $layersYaml = Get-Content $layersPath -Raw | ConvertFrom-Yaml
+    $mod.LayerNames = $layersYaml.layers  # {layer: name} mapping
+    $mod.AgentDependent = $layersYaml.agent_dependent  # {layer: {name, fragments}}
```

Reason: Load build_layers.yaml into Builder module.

---

### Commit 68: `book-0-builder/host-sdk/modules/Builder.ps1` - Add LayerName method

```diff
+    Add-ScriptMethods $Builder @{
+        LayerName = {
+            param([int]$Layer)
+            if ($mod.AgentDependent.ContainsKey($Layer)) {
+                return $mod.AgentDependent[$Layer].name
+            }
+            if ($mod.LayerNames.ContainsKey($Layer)) {
+                return $mod.LayerNames[$Layer]
+            }
+            return "Layer $Layer"
+        }
+    }
```

Reason: Get display name for layer number.

---

### Commit 69: `book-0-builder/host-sdk/modules/Builder.ps1` - Add LayerFragments method

```diff
+    Add-ScriptMethods $Builder @{
+        LayerFragments = {
+            param([int]$Layer)
+            # Agent-dependent levels use override fragments
+            if ($mod.AgentDependent.ContainsKey($Layer)) {
+                return $mod.AgentDependent[$Layer].fragments
+            }
+            # Normal levels derive from build_layer via Fragments module
+            return $mod.SDK.Fragments.UpTo($Layer) | ForEach-Object { $_.Name }
+        }
+    }
```

Reason: Get fragments for layer - uses Fragments.UpTo() for normal levels, override for agent-dependent.

---

### Commit 70: `book-0-builder/host-sdk/modules/Builder.ps1` - Remove SDK.Runner singleton

```diff
-    $Runner = New-Object PSObject -Property @{}
-    Add-ScriptProperties $Runner @{
-        Rendered = {
-            return $mod.SDK.Settings.Virtualization.Runner
-        }
-    # ... Runner properties and methods ...
-    }
-    $Runner = $SDK.Multipass.Worker($Runner)
-
-    # ... more Runner code ...
-
-    $SDK.Extend("Runner", $Runner)
```

Reason: Remove singleton pattern. Use CloudInitBuild.CreateWorker() with Settings.Virtualization.Runner config instead.

---

### Testing Module - Delegate to Builder

---

### Commit 71: `book-0-builder/host-sdk/modules/Testing.ps1` - Delegate LevelName to Builder

```diff
+    Add-ScriptMethods $Testing @{
+        LevelName = {
+            param([int]$Layer)
+            return $mod.SDK.Builder.LayerName($Layer)
+        }
+    }

     $SDK.Extend("Testing", $Testing)
```

Reason: Testing delegates layer name lookup to Builder module.

---

### Commit 72: `book-0-builder/host-sdk/modules/Testing.ps1` - Delegate LevelFragments to Builder

```diff
+    Add-ScriptMethods $Testing @{
+        LevelFragments = {
+            param([int]$Layer)
+            return $mod.SDK.Builder.LayerFragments($Layer)
+        }
+        IncludeArgs = {
+            param([int]$Layer)
+            $fragments = $this.LevelFragments($Layer)
+            return ($fragments | ForEach-Object { "-i $_" }) -join " "
+        }
+    }

     $SDK.Extend("Testing", $Testing)
```

Reason: Testing delegates layer operations to Builder, adds IncludeArgs convenience method.

---

### Commit 73: Delete `book-0-builder/host-sdk/modules/Config.ps1`

File deletion - replaced by Builder.ps1 layer methods + config/build_layers.yaml.

Reason: Old hardcoded PowerShell mapping replaced with build_layer-driven approach.

---

### Network/Vbox Updates

---

### Commit 74: `book-0-builder/host-sdk/modules/Network.ps1` - Update WaitForSSH signature

```diff
         WaitForSSH = {
             param(
                 [Parameter(Mandatory = $true)]
                 [string]$Address,
                 [int]$Port = 22,
-                [int]$TimeoutSeconds = 300
+                [int]$TimeoutSeconds = 300,
+                [bool]$Throw = $true
             )
-            $timedOut = $this.UntilSSH($Address, $Port, $TimeoutSeconds)
-            if ($timedOut) {
-                throw "Timed out waiting for SSH on ${Address}:${Port}"
-            }
-            return $true
```

Reason: Add -Throw parameter (default true for backward compat), remove UntilSSH call.

---

### Commit 75: `book-0-builder/host-sdk/modules/Network.ps1` - WaitForSSH body with job logic

```diff
         WaitForSSH = {
             param(
                 [Parameter(Mandatory = $true)]
                 [string]$Address,
                 [int]$Port = 22,
                 [int]$TimeoutSeconds = 300,
                 [bool]$Throw = $true
             )
+            $timedOut = $mod.SDK.Job({
+                while (-not $SDK.Network.TestSSH($Address, $Port)) {
+                    Start-Sleep -Seconds 5
+                }
+            }, $TimeoutSeconds, @{ Address = $Address; Port = $Port })
+            if ($timedOut -and $Throw) {
+                throw "Timed out waiting for SSH on ${Address}:${Port}"
+            }
+            return -not $timedOut
         }
```

Reason: Inline job logic from UntilSSH, return bool (true=success), throw if -Throw (default).

---

### Commit 76: `book-0-builder/host-sdk/modules/Network.ps1` - Remove UntilSSH method

```diff
-        UntilSSH = {
-            param(
-                [Parameter(Mandatory = $true)]
-                [string]$Address,
-                [int]$Port = 22,
-                [int]$TimeoutSeconds
-            )
-            return $mod.SDK.Job({
-                while(-not $SDK.Network.TestSSH($Address, $Port)) {
-                    Start-Sleep -Seconds 5
-                }
-            }, $TimeoutSeconds, @{
-                Address = $Address
-                Port = $Port
-            })
-        }
```

Reason: UntilSSH logic merged into WaitForSSH - remove duplicate method.

---

### Commit 77: `book-0-builder/host-sdk/modules/Vbox.ps1` - SSH defaults to null

```diff
     $mod.Configurator = @{
         Defaults = @{
             CPUs = 2
             Memory = 4096
             Disk = 40960
-            SSHUser = "ubuntu"
-            SSHHost = "localhost"
-            SSHPort = 2222
+            SSHUser = $null
+            SSHHost = $null
+            SSHPort = $null
         }
     }
```

Reason: SSH connection details should derive from config, not hardcoded.

---

### Commit 78: `book-0-builder/host-sdk/modules/Vbox.ps1` - SSH derivation in Rendered

```diff
             Rendered = {
                 $config = $this.Config
                 $defaults = if ($this.Defaults) { $this.Defaults } else { $mod.Configurator.Defaults }
                 $rendered = @{}
                 foreach ($key in $defaults.Keys) { $rendered[$key] = $defaults[$key] }
                 foreach ($key in $config.Keys) { $rendered[$key] = $config[$key] }
+                # Derive SSH settings from identity.config.yaml if not set
+                if (-not $rendered.SSHUser -or -not $rendered.SSHHost -or -not $rendered.SSHPort) {
+                    $identity = $mod.SDK.Settings.Load("book-2-cloud/users/config/identity.config.yaml")
+                    if (-not $rendered.SSHUser) { $rendered.SSHUser = $identity.identity.username }
+                    if (-not $rendered.SSHHost) { $rendered.SSHHost = "localhost" }
+                    if (-not $rendered.SSHPort) { $rendered.SSHPort = 2222 }
+                }
                 if (-not $rendered.MediumPath) {
```

Reason: Use Settings.Load() to derive SSH settings from identity config.

---

## Validation (Review #1)

After Review #1 commits:

**Makefile:**
- [ ] `make cloud-init LAYER=3` builds with fragments up to layer 3
- [ ] `make cloud-init INCLUDE="-i users -i ssh"` works with new fragment names
- [ ] `make help` shows LAYER parameter

**Python:**
- [ ] `python -m builder render cloud-init --layer 3` filters by build_layer

**Builder Module:**
- [ ] `$SDK.Builder.LayerName(3)` returns "Users"
- [ ] `$SDK.Builder.LayerName(16)` returns "Package Manager Updates"
- [ ] `$SDK.Builder.LayerFragments(3)` returns fragments from layers 0-3
- [ ] `$SDK.Builder.LayerFragments(16)` returns [packages, pkg-security, pkg-upgrade]

**Testing Module (delegates):**
- [ ] `$SDK.Testing.LevelName(3)` returns "Users" (delegates to Builder)
- [ ] `$SDK.Testing.LevelFragments(3)` returns same as Builder.LayerFragments(3)
- [ ] `$SDK.Testing.IncludeArgs(3)` returns "-i base -i network -i kernel -i users"

**SDK.Runner Removed:**
- [ ] `$SDK.Runner` does not exist
- [ ] `$SDK.CloudInitBuild.CreateWorker()` uses Settings.Virtualization.Runner config

**Network/Vbox:**
- [ ] `$SDK.Network.WaitForSSH(...)` throws on timeout (default -Throw $true)
- [ ] `$SDK.Network.WaitForSSH(..., -Throw $false)` returns bool without throwing
- [ ] `$SDK.Vbox.Worker(@{...}).SSHUser` derives from identity.config.yaml
