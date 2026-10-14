# JSON Regex Search

Search JSON files recursively with a regular expression and find the matching values together with their location and surrounding objects. Use the browser-based tool for a quick local search, or the PowerShell function when you want structured results in a shell.

This can be useful for exploring large exports, such as [Microsoft 365 DSC](https://microsoft365dsc.com/) or [Microsoft Entra tenant governance](https://learn.microsoft.com/en-us/entra/id-governance/tenant-governance/configuration-management) JSON files.

Both versions search **string values**, or property names, and skip values whose property name is `Id`.

## Browser version

Open [JSON Regex Search](https://martin.rublik.eu/json-regex-search), select a JSON file, enter a regular expression, and select **Search**. Results include the matching value, its path, and its parent and top-level object. You can also enter comma-separated property paths to display selected fields from each top-level object; nested fields can use dot notation.

The browser version processes the selected file locally in your browser; it does not upload the JSON. Its source is in [`docs/`](./docs/).

## PowerShell version

The PowerShell function uses the [`jq`](https://jqlang.org/download/) executable, which must be available on your `PATH`.

Dot-source the script, then call `Find-JsonMatch` with a regular expression and the JSON file path:

```powershell
. ./powershell/Find-JsonMatch.ps1
. ./powershell/Sort-ObjectProperties.ps1
Find-JsonMatch -Regex 'sam_account_name' -FileName './export.json'
```

Each result contains:

| Property | Description |
| --- | --- |
| `value` | The string value matched by the regular expression. |
| `path` | A jq-style path to the matching value, with array indexes in brackets. |
| `parent` | The immediate containing object or array. |
| `object` | The top-level value containing the match, useful when the JSON root is an array. |

## Repository contents

- [`powershell/Find-JsonMatch.ps1`](./powershell/Find-JsonMatch.ps1): PowerShell function backed by `jq`.
- [`powershell/Find-JsonMatch.ps1`](./powershell/Sort-ObjectProperties.ps1): PowerShell function to sort an object alphabetically. This way the JSON export is easier to compare via traditional diff tools.
- [`docs/index.html`](./docs/index.html): Standalone browser-based search tool, also published through GitHub Pages.
