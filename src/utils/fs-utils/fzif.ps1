<#
.SYNOPSIS
    Fuzzy-find files using fzf.

.DESCRIPTION
    Recursively lists files and pipes them into fzf for interactive fuzzy search.
    Outputs the selected file as plain text or a terminal hyperlink.
    Can optionally open the file with the default application.

.PARAMETER Path
    Optional starting path. Defaults to the current directory.
    Accepts pipeline input.

.PARAMETER NoHyperLink
    Output plain text instead of a terminal hyperlink.

.PARAMETER Open
    Open the selected file using the default application.

.PARAMETER Help
    Show help for this function.

.EXAMPLE
    fzif
    Fuzzy-find files from the current directory.

.EXAMPLE
    fzif -Open
    Fuzzy-find and open the selected file.

.EXAMPLE
    'C:\Projects' | fzif
    Use a custom root path via pipeline input.

.LINK
    https://github.com/patppuccin/pwshy
#>
function fzif {
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromRemainingArguments
        )]
        [string[]]$Path,

        [switch]$NoHyperLink,
        [switch]$Open,

        [Alias('h')]
        [switch]$Help
    )

    begin {
        if ($Help -or $Path -contains '--help' -or $Path -contains '-help') {
            $MyInvocation.MyCommand | Get-Help
            break
        }

        if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
            throw "fzf is not installed or not available in PATH"
        }

        $roots = @()
    }

    process {
        if ($Path) {
            $roots += $Path
        }
    }

    end {
        if (-not $roots) {
            $roots = @((Get-Location).Path)
        }

        $file = Get-ChildItem $roots -Recurse -File -EA SilentlyContinue |
        Select-Object -ExpandProperty FullName |
        fzf --height 40% --border=rounded --reverse `
            --prompt="Search Files: " `
            --highlight-line

        if (-not $file) { return }

        if ($Open) {
            Invoke-Item $file -EA SilentlyContinue
            return
        }

        if ($NoHyperLink) {
            Write-Host $file
            return
        }

        $esc = [char]27
        Write-Host "${esc}]8;;file:///$file`a$file${esc}]8;;`a"
    }
}
