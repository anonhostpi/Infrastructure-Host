param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Fragments -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Fragments = New-Object PSObject

    $Fragments | Add-Member -MemberType ScriptProperty -Name Layers -Value {
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

    $SDK.Extend("Fragments", $Fragments)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
