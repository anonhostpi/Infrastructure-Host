# Plan: Book 0 - Builder SDK Updates

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_0/INITIAL.md`

---

## Overview

Update the builder-sdk to discover fragments in the new `book-*/` structure instead of hardcoded `src/` paths. The SDK should auto-discover fragments by scanning for `build.yaml` files.

---

## Files to Modify

### Commit 1: `book-0-builder/builder-sdk/renderer.py` - Add fragment discovery function

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

### Commit 2: `book-0-builder/builder-sdk/renderer.py` - Update create_environment signature

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

### Commit 3: `book-0-builder/builder-sdk/renderer.py` - Update get_environment

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

### Commit 4: `book-0-builder/builder-sdk/renderer.py` - Update render_scripts

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

### Commit 5: `book-0-builder/builder-sdk/renderer.py` - Update render_script path handling

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

### Commit 6: `book-0-builder/builder-sdk/renderer.py` - Update get_available_fragments

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

### Commit 7: `book-0-builder/builder-sdk/renderer.py` - Update render_cloud_init (part 1)

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

### Commit 8: `book-0-builder/builder-sdk/renderer.py` - Update render_cloud_init (part 2)

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

### Commit 9: `book-0-builder/builder-sdk/renderer.py` - Update render_cloud_init (part 3)

```diff
-        # Use forward slashes for Jinja2 (cross-platform)
-        template_path = tpl_path.relative_to('src').as_posix()
+        template_path = tpl_path.as_posix()
         rendered = render_text(ctx, template_path, scripts=scripts)
```

Reason: Remove `relative_to('src')` - use direct path.

---

### Commit 10: `book-0-builder/builder-sdk/renderer.py` - Update render_autoinstall

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

### Commit 11: `book-0-builder/host-sdk/modules/Config.ps1` - Update fragment mappings (part 1)

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

### Commit 12: `book-0-builder/host-sdk/modules/Config.ps1` - Update fragment mappings (part 2)

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

### Commit 13: `book-0-builder/host-sdk/modules/Config.ps1` - Update fragment mappings (part 3)

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

### Commit 14: `book-0-builder/host-sdk/modules/Config.ps1` - Update fragment mappings (part 4)

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

### Commit 15: `book-0-builder/host-sdk/modules/Config.ps1` - Update fragment mappings (part 5)

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

### Commit 16: `book-0-builder/host-sdk/SDK.ps1` - Fix module path references

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

### Commit 17: `book-0-builder/host-sdk/SDK.ps1` - Add Logger module loading

```diff
+    & "$PSScriptRoot/modules/Logger.ps1" -SDK $SDK
     & "$PSScriptRoot/modules/Settings.ps1" -SDK $SDK
```

Reason: Logger must load first so other modules can use `$SDK.Log.*`.

---

### Commit 18: Create `book-0-builder/host-sdk/modules/Logger.ps1` - module shape

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

### Commit 19: `book-0-builder/host-sdk/modules/Logger.ps1` - Add Write and level methods

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

### Commit 20: `book-0-builder/host-sdk/modules/Logger.ps1` - Add transcript methods

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

### Commit 21: Create `book-0-builder/host-sdk/helpers/Worker.ps1`

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

### Commit 22: `book-0-builder/host-sdk/helpers/Worker.ps1` - Add Test method signature

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

### Commit 23: `book-0-builder/host-sdk/helpers/Worker.ps1` - Add Test method body

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

### Commit 24: `book-0-builder/host-sdk/modules/Multipass.ps1` - Add Network/CloudInit properties

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

### Commit 25: `book-0-builder/host-sdk/modules/Multipass.ps1` - Remove Ensure from Worker.Methods

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

### Commit 26: `book-0-builder/host-sdk/modules/Multipass.ps1` - Call Worker helper

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

### Commit 27: `book-0-builder/host-sdk/modules/Multipass.ps1` - Update Create to use CloudInit

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

### Commit 28: Create `book-0-builder/host-sdk/modules/Fragments.ps1` - module shape

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

### Commit 29: `book-0-builder/host-sdk/modules/Fragments.ps1` - Add Layers property

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

### Commit 30: `book-0-builder/host-sdk/modules/Fragments.ps1` - Add query methods

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

### Commit 31: `book-0-builder/host-sdk/SDK.ps1` - Add Fragments module loading

```diff
     & "$PSScriptRoot/modules/Settings.ps1" -SDK $SDK
+    & "$PSScriptRoot/modules/Fragments.ps1" -SDK $SDK
     & "$PSScriptRoot/modules/Network.ps1" -SDK $SDK
```

Reason: Load Fragments module after Settings (needs ConvertFrom-Yaml).

---

### Commit 32: `book-0-builder/host-sdk/modules/Network.ps1` - Add WaitForSSH method

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

### Commit 33: Create `book-0-builder/host-sdk/modules/Testing.ps1` - module shape

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

### Commit 34: `book-0-builder/host-sdk/modules/Testing.ps1` - Add All property and tracking methods

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

### Commit 35: `book-0-builder/host-sdk/modules/Testing.ps1` - Add Summary method

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

### Commit 36: `book-0-builder/host-sdk/modules/Testing.ps1` - Add layer query methods

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

### Commit 37: `book-0-builder/host-sdk/SDK.ps1` - Add Testing module loading

```diff
     & "$PSScriptRoot/modules/Builder.ps1" -SDK $SDK
+    & "$PSScriptRoot/modules/Testing.ps1" -SDK $SDK
```

Reason: Load Testing module after Builder.

---

### Commit 38: `book-0-builder/host-sdk/modules/Builder.ps1` - Add Clean method (line 64)

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

### Commit 39: `book-0-builder/host-sdk/modules/Builder.ps1` - Update Build method (line 85)

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

### Commit 40: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add Configurator defaults (line 14)

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

### Commit 41: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add Worker structure (line 16)

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

### Commit 42: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add Worker property accessors

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

### Commit 43: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add Worker lifecycle methods

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

### Commit 44: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add Worker Create/Exec methods

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

### Commit 45: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add Worker factory (line 26)

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

### Commit 46: Create `book-0-builder/host-sdk/modules/CloudInitBuild.ps1` - module shape

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

### Commit 47: `book-0-builder/host-sdk/modules/CloudInitBuild.ps1` - Add Build and CreateWorker

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

### Commit 48: `book-0-builder/host-sdk/modules/CloudInitBuild.ps1` - Add Cleanup

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

### Commit 49: Create `book-0-builder/host-sdk/modules/CloudInitTest.ps1` - module shape

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

### Commit 50: `book-0-builder/host-sdk/modules/CloudInitTest.ps1` - Add Run method

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

### Commit 51: Create `book-0-builder/host-sdk/modules/AutoinstallBuild.ps1` - module shape

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

### Commit 52: `book-0-builder/host-sdk/modules/AutoinstallBuild.ps1` - Add GetArtifacts and CreateWorker

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

### Commit 53: `book-0-builder/host-sdk/modules/AutoinstallBuild.ps1` - Add Cleanup

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

### Commit 54: Create `book-0-builder/host-sdk/modules/AutoinstallTest.ps1` - module shape

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

### Commit 55: `book-0-builder/host-sdk/modules/AutoinstallTest.ps1` - Add Run method

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

### Commit 56: `book-0-builder/host-sdk/SDK.ps1` - Add build/test module loading

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
