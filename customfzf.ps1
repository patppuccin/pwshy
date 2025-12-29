
function Invoke-Fzf {
    param (
        [Parameter(Mandatory)]
        [string[]]$Items,

        [string]$Prompt = "Search: "
    )

    $Items = $Items | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    if (-not $Items) { return }

    # Define arguments as a single string or precise array
    $fzfArgs = @(
        "--height=40%"
        "--layout=reverse"
        "--border=rounded"
        "--margin=1,0"
        "--prompt=$Prompt"
        "--highlight-line"
        "--color=16"
        "--wrap"
    )

    # Use Write-Output to stream the items into fzf
    return $Items | & fzf $fzfArgs
}

# function Search-HistoryCommands {
#     # fzih
#     $historyPath = (Get-PSReadLineOption).HistorySavePath
#     if (-not (Test-Path $historyPath)) {
#         return
#     }

#     $history = @(
#         [System.IO.File]::ReadLines($historyPath) | 
#         Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
#     )

#     if ($history.Count -eq 0) {
#         return
#     }

#     $selection = Invoke-Fzf -Items $history -Prompt "History ❯ "

#     if ($selection) {
#         [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selection)
#     }
# }

function Search-HistoryCommands {
    # fzih

    $path = (Get-PSReadLineOption).HistorySavePath
    if (-not [System.IO.File]::Exists($path)) {
        return
    }

    # Read entire file once (fastest overall for reverse traversal)
    $lines = [System.IO.File]::ReadAllLines($path)
    if ($lines.Length -eq 0) {
        return
    }

    # Dedup with preserved recency
    $seen = [System.Collections.Generic.HashSet[string]]::new()
    $history = New-Object System.Collections.Generic.List[string]

    for ($i = $lines.Length - 1; $i -ge 0; $i--) {
        $line = $lines[$i]

        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        if ($seen.Add($line)) {
            $history.Add($line)
        }
    }

    if ($history.Count -eq 0) {
        return
    }

    # Convert once for native invocation
    $selection = Invoke-Fzf -Items $history.ToArray() -Prompt "History ❯ "

    # Clear the function call remnant from the command line
    [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteLine()
    
    if ($selection) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selection)
    }
}
Set-Alias fzih Search-HistoryCommands

function Search-SessionCommands {
    # fzic
    $HistoryCommands = @((Get-History).CommandLine | Select-Object -Unique)
    $selection = Invoke-Fzf -Items $HistoryCommands -Prompt "Search (session commands): "
    
    # Clear the function call remnant from the command line
    [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteLine()
    Start-Sleep -Milliseconds 1000
    
    if ($selection) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selection)
    }
}
Set-Alias fzic Search-SessionCommands

function Search-Snippets {}
Set-Alias fzis Search-Snippets
