function Sort-ObjectProperties {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [object]$InputObject
    )

    process {

        if ($null -eq $InputObject) {
            return $null
        }

        # Handle scalar values
        if (
            $InputObject -is [string] -or
            $InputObject -is [ValueType]
        ) {
            return $InputObject
        }

        # Handle arrays and collections
        if (
            $InputObject -is [System.Collections.IEnumerable] -and
            $InputObject -isnot [System.Collections.IDictionary] -and
            $InputObject -isnot [string]
        ) {

            $items = [System.Collections.Generic.List[object]]::new()

            foreach ($item in $InputObject) {
                $normalized = Sort-ObjectProperties -InputObject $item
                $items.Add($normalized)
            }

            $entries = foreach ($item in $items) {

                $sortKey = $null

                if ($item -is [System.Collections.IDictionary]) {

                    # Prefer stable identifiers for object arrays
                    foreach ($property in @(
                        'ResourceAppId'
                        'Id'
                        'Name'
                        'DisplayName'
                    )) {
                        if (
                            $item.Contains($property) -and
                            $null -ne $item[$property]
                        ) {
                            $sortKey = [string]$item[$property]
                            break
                        }
                    }
                }

                # Fallback to canonical JSON representation
                if ($null -eq $sortKey) {
                    $sortKey = ConvertTo-Json `
                        -InputObject $item `
                        -Depth 100 `
                        -Compress
                }

                [PSCustomObject]@{
                    Key   = $sortKey
                    Json  = ConvertTo-Json -InputObject $item -Depth 100 -Compress
                    Value = $item
                }
            }

            # Explicit ordinal sorting with a secondary tie-breaker
            $comparer = [StringComparer]::Ordinal

            $sortedEntries = @(
                $entries | Sort-Object `
                    @{ Expression = { $_.Key } },
                    @{ Expression = { $_.Json } }
            )

            $result = [object[]]@(
                foreach ($entry in $sortedEntries) {
                    $entry.Value
                }
            )

            return ,$result
        }

        # Convert arbitrary .NET / Graph SDK objects to dictionaries
        if ($InputObject -is [System.Collections.IDictionary]) {
            $properties = $InputObject
        }
        else {
            $properties = [ordered]@{}

            foreach ($property in $InputObject.PSObject.Properties) {
                if ($property.IsGettable) {
                    $properties[$property.Name] = $property.Value
                }
            }
        }

        $scalarKeys  = [System.Collections.Generic.List[string]]::new()
        $complexKeys = [System.Collections.Generic.List[string]]::new()

        foreach ($key in $properties.Keys) {

            $value = $properties[$key]

            $isComplex = (
                $value -is [System.Collections.IEnumerable] -and
                $value -isnot [string]
            ) -or (
                $null -ne $value -and
                $value -isnot [string] -and
                $value -isnot [ValueType]
            )

            if ($isComplex) {
                $complexKeys.Add([string]$key)
            }
            else {
                $scalarKeys.Add([string]$key)
            }
        }

        $scalarKeys.Sort([StringComparer]::Ordinal)
        $complexKeys.Sort([StringComparer]::Ordinal)

        $result = [ordered]@{}

        foreach ($key in $scalarKeys) {
            $result[$key] = Sort-ObjectProperties -InputObject $properties[$key]
        }

        foreach ($key in $complexKeys) {
            $result[$key] = Sort-ObjectProperties -InputObject $properties[$key]
        }

        return $result
    }
}