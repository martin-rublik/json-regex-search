function Sort-ObjectProperties {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [object]$InputObject
    )

    process {

        # Null
        if ($null -eq $InputObject) {
            return $null
        }

        # Hashtable / Dictionary
        if ($InputObject -is [System.Collections.IDictionary]) {
            $result = [ordered]@{}

            # Sort properties:
            #   1. Scalar/string values first
            #   2. Enumerable/dictionary values second
            #   3. Alphabetically by key
            $sortedKeys = $InputObject.Keys | Sort-Object `
                @{
                    Expression = {
                        $value = $InputObject[$_]
                        
                        # sort IEnurable vs. string and not IEnumerable
                        # $false is first
                        # $true is second
                        $value -is [System.Collections.IEnumerable] -and
                        $value -isnot [string]
                    }
                },
                @{
                    # after the objects are sorted by IEnumerable vs. values, sort by value
                    Expression = { $_ }
                }

            foreach ($key in $sortedKeys) {
                $result[$key] = Sort-ObjectRecursive $InputObject[$key]
            }

            return $result
        }

        # Enumerable, but NOT string
        if (
            $InputObject -is [System.Collections.IEnumerable] -and
            $InputObject -isnot [string]
        ) {
            # First recursively normalize all elements
            $items = @(
                foreach ($item in $InputObject) {
                    Sort-ObjectRecursive $item
                }
            )

            # Sort array elements
            return @(
                $items | Sort-Object {
                    $item = $_

                    if ($item -is [System.Collections.IDictionary]) {

                        # Build deterministic sorting value from
                        # all scalar properties of the dictionary.
                        $scalarValues = foreach ($key in $item.Keys) {
                            $value = $item[$key]

                            if (
                                $value -isnot [System.Collections.IEnumerable] -or
                                $value -is [string]
                            ) {
                                "$key=$value"
                            }
                        }

                        return ($scalarValues -join '|')
                    }

                    # Scalar array element
                    return "$item"
                }
            )
        }

        # Non-enumerable scalar, including strings
        return $InputObject
    }
}
