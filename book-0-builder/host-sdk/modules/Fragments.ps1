param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Fragments -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    # Use centralized layers config from Settings
    $mod.LayerNames = $mod.SDK.Settings.Layers.layers

    $Fragments = New-Object PSObject

    Add-ScriptProperties $Fragments @{
        Layers = {
            $results = @()
            Get-ChildItem -Path @("book-1-foundation", "book-2-cloud") -Recurse -Filter "build.yaml" |
            ForEach-Object {
                $meta = Get-Content $_.FullName -Raw | ConvertFrom-Yaml
                $results += [PSCustomObject]@{
                    Name = $meta.name
                    Path = $_.DirectoryName
                    Order = $meta.build_order
                    Layer = $meta.build_layer
                    IsoRequired = $meta.iso_required
                }
            }
            return $results | Sort-Object Order
        }
    }

    Add-ScriptMethods $Fragments @{
        UpTo = {
            param([int]$Layer)
            return $this.Layers | Where-Object {
                $l = $_.Layer
                if ($l -is [array]) {
                    $l | Where-Object { $_ -le $Layer } | Select-Object -First 1
                } else {
                    $l -le $Layer
                }
            }
        }
        At = {
            param([int]$Layer)
            return $this.Layers | Where-Object {
                $l = $_.Layer
                if ($l -is [array]) {
                    $l -contains $Layer
                } else {
                    $l -eq $Layer
                }
            }
        }
        IsoRequired = {
            return $this.Layers | Where-Object { $_.IsoRequired }
        }
    }

    Add-ScriptMethods $Fragments @{
        LayerName = {
            param([int]$Layer)
            if ($mod.LayerNames -and $mod.LayerNames.ContainsKey($Layer)) {
                return $mod.LayerNames[$Layer]
            }
            return "Layer $Layer"
        }
    }

    $SDK.Extend("Fragments", $Fragments)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
