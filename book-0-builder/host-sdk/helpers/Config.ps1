New-Module -Name Helpers.Config -ScriptBlock {

    # Deep merge override into base (mirrors Python composer.deep_merge)
    function Merge-DeepHashtable {
        param(
            [hashtable]$Base,
            [hashtable]$Override
        )

        $result = $Base.Clone()
        foreach ($key in $Override.Keys) {
            if ($result.ContainsKey($key)) {
                if ($result[$key] -is [hashtable] -and $Override[$key] -is [hashtable]) {
                    $result[$key] = Merge-DeepHashtable -Base $result[$key] -Override $Override[$key]
                } elseif ($result[$key] -is [array] -and $Override[$key] -is [array]) {
                    $result[$key] = $result[$key] + $Override[$key]
                } else {
                    $result[$key] = $Override[$key]
                }
            } else {
                $result[$key] = $Override[$key]
            }
        }
        return $result
    }

    # Load configuration from YAML files
    # Mirrors Python BuildContext: loads all *.config.yaml, auto-unwraps, applies testing overrides
    function Build-TestConfig {
        param(
            [string]$ConfigDir = "src/config"
        )

        Import-Module powershell-yaml -ErrorAction SilentlyContinue

        $config = @{}

        $git_root = git rev-parse --show-toplevel 2>$null
        $ConfigDir = Join-Path $git_root $ConfigDir

        # Load all *.config.yaml files (mirrors BuildContext.__init__)
        $configFiles = Get-ChildItem -Path $ConfigDir -Filter "*.config.yaml" -ErrorAction SilentlyContinue
        foreach ($file in $configFiles) {
            $key = $file.Name -replace '\.config\.yaml$', ''
            $content = Get-Content $file.FullName -Raw
            $yaml = ConvertFrom-Yaml $content

            # Auto-unwrap: if single key matches filename, unwrap it
            if ($yaml -is [hashtable] -and $yaml.Count -eq 1) {
                $onlyKey = @($yaml.Keys)[0]
                if ($onlyKey -eq $key) {
                    $yaml = $yaml[$onlyKey]
                }
            }

            $config[$key] = $yaml
        }

        # Apply testing config overrides (mirrors BuildContext._apply_testing_overrides)
        $testingConfig = $config['testing']
        if ($testingConfig -is [hashtable] -and $testingConfig['testing'] -eq $true) {
            foreach ($key in $testingConfig.Keys) {
                if ($key -eq 'testing') { continue }

                if ($config.ContainsKey($key) -and $testingConfig[$key] -is [hashtable]) {
                    # Deep merge testing override into main config
                    $config[$key] = Merge-DeepHashtable -Base $config[$key] -Override $testingConfig[$key]
                } elseif ($testingConfig[$key] -is [hashtable]) {
                    # New config section from testing
                    $config[$key] = $testingConfig[$key]
                }
            }
        }

        return $config
    }

    Export-ModuleMember -Function Build-TestConfig
} | Import-Module -Force