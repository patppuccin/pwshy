function Invoke-Fzf {
    param (
        [Parameter(Mandatory)]
        [string[]]$Items,

        [string]$Prompt = "Search: "
    )

    $Items = $Items | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    if (-not $Items) { return }

    $fzfArgs = @(
        "--height=40%"
        "--layout=reverse"
        "--border=rounded"
        "--margin=1,0"
        "--prompt=$Prompt"
        "--highlight-line"
        "--color=16"
        "--wrap",
        "--expect=enter"
    )

    return $Items | & fzf $fzfArgs | Select-Object -Skip 1
}

function Search-HistoryCommands {
    # fzih
    $path = (Get-PSReadLineOption).HistorySavePath
    if (-not [System.IO.File]::Exists($path)) {
        return
    }

    $lines = [System.IO.File]::ReadAllLines($path)
    if ($lines.Length -eq 0) {
        return
    }

    # Deduplicate with preserved recency (most recent first)
    $seen = [System.Collections.Generic.HashSet[string]]::new()
    $history = [System.Collections.Generic.List[string]]::new()

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

    $selection = Invoke-Fzf -Items $history.ToArray() -Prompt "History ❯ "

    [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteLine()
    
    if ($selection) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selection)
    }
}
Set-Alias fzih Search-HistoryCommands

function Search-SessionCommands {
    # fzic
    $historyCommands = @((Get-History).CommandLine | Select-Object -Unique)
    if ($historyCommands.Count -eq 0) {
        return
    }

    $selection = Invoke-Fzf -Items $historyCommands -Prompt "Session ❯ "
    
    [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteLine()
    Start-Sleep -Seconds 1

    if ($selection) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selection)
        Start-Sleep -Seconds 1 # --- till here, it works clean.
    }

}
Set-Alias fzic Search-SessionCommands

function Search-Snippets {
    # fzis - Placeholder for future implementation
}
Set-Alias fzis Search-Snippets