New-Module -Name Helpers.PowerShell -ScriptBlock {
    function Test-Primitive {
        param( $Value )

        return (& {
            $null -eq $Value
            
            $Value -is [bool]
            $Value -is [switch]

            $Value -is [byte]
            $Value -is [sbyte]
            
            $Value -is [char]
            $Value -is [string]

            $Value -is [int16]
            $Value -is [int32]
            $Value -is [int64]
            $Value -is [uint16]
            $Value -is [uint32]
            $Value -is [uint64]

            $Value -is [single]
            $Value -is [double]

            Try {
                $Value -is [int128]
                $Value -is [uint128]

                $Value -is [decimal]
            } Catch {}
        }) -contains $true
    }
    function ConvertTo-OrderedHashtable {
        param (
            [Parameter(Mandatory)]
            $InputObject,
            $TypeException,
            [switch] $Shallow
        )

        if ($InputObject -is [System.Collections.IDictionary]) {
            # Convert dictionaries to ordered hashtable
            $orderedHashtable = [ordered]@{}
            foreach ($key in $InputObject.Keys) {
                $orderedHashtable[$key] = If( $Shallow ) {
                    $InputObject[$key]
                } ElseIf( $null -ne $InputObject[$key] ){
                    ConvertTo-OrderedHashtable -InputObject $InputObject[$key] -TypeException $TypeException
                } Else {
                    $null
                }
            }
            return $orderedHashtable
        }
        elseif ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            # Convert arrays/lists recursively
            $out = foreach( $in in $InputObject ){
                If( $null -ne $in ){
                    $p = @{
                        InputObject = $in
                        TypeException = $TypeException
                    }
                    If( $Shallow ){ $p.Shallow = $true }
                    ConvertTo-OrderedHashtable @p
                } Else {
                    $null
                }
            }
            return @($out)
        }
        elseif (-not (Test-Primitive $InputObject) -and -not ($TypeException -and $InputObject -is $TypeException)) {
            # Convert PSObject to ordered hashtable
            $orderedHashtable = [ordered]@{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $value = $property.Value
                $orderedHashtable[$property.Name] = If( $Shallow ) {
                    $value
                } ElseIf( $null -ne $value ){
                    ConvertTo-OrderedHashtable -InputObject $value -TypeException $TypeException
                } Else {
                    $null
                }
            }
            return $orderedHashtable
        }
        else {
            # Return primitive values directly
            return $InputObject
        }
    }

    function Add-ScriptMethods {
        param(
            [psobject] $Target,
            [System.Collections.IDictionary] $Members
        )

        $keys = $Members.Keys | ForEach-Object { $_ }

        If( $keys.Count ){
            $keys | ForEach-Object {
                $target | Add-Member -MemberType ScriptMethod -Name $_ -Value $Members[$_] -Force
            }
        }
    }

    function Add-ScriptProperties {
        param(
            [psobject] $Target,
            [System.Collections.IDictionary] $GetterSetters
        )

        $keys = $GetterSetters.Keys | ForEach-Object { $_ }

        If( $keys.Count ){
            $keys | ForEach-Object {
                If( $GetterSetters[$_] -is [scriptblock] ){
                    $GetterSetters[$_] = @{
                        Getter = $GetterSetters[$_]
                        Setter = $null
                    }
                }
                $target | Add-Member -MemberType ScriptProperty -Name $_ -Value $GetterSetters[$_].Getter -SecondValue $GetterSetters[$_].Setter -Force
            }
        }
    }

    Export-ModuleMember -Function ConvertTo-OrderedHashtable,Add-ScriptMethods,Test-Primitive,Add-ScriptProperties
} | Import-Module -Force