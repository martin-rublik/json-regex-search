function Find-JsonMatch
{
    param(
        [string]$Regex,
        [string]$FileName
)

    # Get all the occurences of the group name in the JSON file and convert them to JPaths
    # [] - we use square brackets to create an array of objects with the path, value and top level object for each occurence 
    # {} after select is used to create a custom object
    # path() -  https://jqlang.org/manual/#path
    #   The path() function returns the path to each value in the input.
    # .. - recursive descent operator, it searches for the group name at any level of the JSON structure - https://jqlang.org/manual/#recursive-descent
    # path - use the variable $p and convert the array in a following way, if it is a number wrap it in [], if it is a string just use the string, then join with "." to create a JPath expression
    # value - get the value of the occurence using the getpath function and the path stored in $p
    # object - get the top level object of the occurence using the getpath function


    $retval=jq "
        [
            path(.. | select(type == ""string"" and test(""$Regex""))) as `$p 
            | select(`$p[-1] != ""Id"")
            |   {
                    path: (
                        `$p
                        | map(
                            if type == ""number""
                                then ""["" + tostring + ""]""
                                else tostring
                            end
                        )
                        | ""."" + join(""."")
                    ),
                    value: getpath(`$p),
                    parent: getpath(`$p[:-1]),
                    object: getpath([`$p[0]])
                }
        ]
        " $fileName | ConvertFrom-Json

    return $retval 
}
