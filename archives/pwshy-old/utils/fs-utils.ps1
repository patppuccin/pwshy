# ==== Helper Functions ====================================

function Get-ArchiveTool {
    param([string]$filename)
    
    $lc = $filename.ToLowerInvariant()
    switch -regex ($lc) {
        '\.(zip|tar|gz|tgz|bz2|tar\.gz|tar\.bz2|xz|tar\.xz)$' { "tar" }
        '\.(7z|rar)$' { "7z" }
        default { $null }
    }
}

function Test-ToolAvailable {
    param([string]$tool)
    
    switch ($tool) {
        "tar" { Get-Command tar.exe -ErrorAction SilentlyContinue }
        "7z" { Get-Command 7z.exe  -ErrorAction SilentlyContinue }
    }
}

# ==== Utility Functions ===================================

$helpTouch = @"
`nUsage: touch [file ...]

Create files if missing or update their timestamps if present.
"@

function touch {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Path,

        [Alias('h')]
        [switch]$Help
    )

    # Handle --help, -help, -h, -Help
    if ($Help -or $args -contains '--help' -or $args -contains '-help') {
        Write-Host $helpTouch
        return
    }

    if (-not $Path) {
        Write-Host $helpTouch
        return
    }

    foreach ($p in $Path) {
        try {
            if (Test-Path $p) {
                (Get-Item $p).LastWriteTime = Get-Date
            }
            else {
                New-Item -ItemType File -Path $p -Force | Out-Null
            }
        }
        catch {
            Write-Host "touch: failed for '$p'" -ForegroundColor Yellow
        }
    }
}

$helpMkcd = @"
`nUsage: mkcd [directory]

Create a directory and cd into it.
"@

function mkcd {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)][string]$Dir,
        [Alias('h')][switch]$Help
    )

    # Handle --help, -help, -h, -Help
    if ($Help -or $args -contains '--help' -or $args -contains '-help') {
        Write-Host $helpMkcd
        return
    }

    if (-not $Dir) {
        Write-Host $helpMkcd
        return
    }

    try {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
        Set-Location $Dir
    }
    catch {
        Write-Host "mkcd: failed for '$Dir'" -ForegroundColor Yellow
    }
}

$helpFzif = @"
`nUsage: fzif [options]

Fuzzy-find files using fzf.

Options:
  -NoHyperLink    Display plain text instead of hyperlink
  -Open           Open the selected file with default application
  -Help, -h       Show this help message
"@

function fzif {
    [CmdletBinding()]
    param(
        [switch]$NoHyperLink,
        [switch]$Open,
        [Alias('h')]
        [switch]$Help
    )

    # Handle --help, -help, -h, -Help
    if ($Help -or $args -contains '--help' -or $args -contains '-help') {
        Write-Host $helpFzif
        return
    }

    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Host "fzf is not installed or not found in PATH. Needed for fzif." -ForegroundColor Red
        return
    }

    $file = Get-ChildItem -Recurse -File -EA SilentlyContinue |
    Select-Object -ExpandProperty FullName |
    fzf --height 40% --border=rounded --margin="1,0" --reverse --prompt="Search Files: " --ghost="Type to search for files" --highlight-line --color=16
    
    if ($file) {
        if ($Open) {
            Invoke-Item $file -ErrorAction SilentlyContinue
        }
        elseif ($NoHyperLink) {
            Write-Host "Selected: $file"
        }
        else {
            $esc = [char]27
            $link = "${esc}]8;;file:///$file`a$file${esc}]8;;`a"
            Write-Host "Selected: $link"
        }
    }
}

$helpFzid = @"
`nUsage: fzid [options]

Fuzzy-find directories using fzf.

Options:
  -NoHyperLink    Display plain text instead of hyperlink
  -Open           Open the selected directory with default application
  -Go             Change into the selected directory
  -Help, -h       Show this help message
"@

function fzid {
    [CmdletBinding()]
    param(
        [switch]$NoHyperLink,
        [switch]$Open,
        [switch]$MoveInto,
        [Alias('h')]
        [switch]$Help
    )

    # Handle --help, -help, -h, -Help
    if ($Help -or $args -contains '--help' -or $args -contains '-help') {
        Write-Host $helpFzid
        return
    }

    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Host "fzf is not installed or not found in PATH. Needed for fzid." -ForegroundColor Red
        return
    }

    $dir = Get-ChildItem -Recurse -Directory -EA SilentlyContinue |
    Select-Object -ExpandProperty FullName |
    fzf --height 40% --border=rounded --margin="1,0" --reverse --prompt="Search Directories: " --ghost="Type to search for directories" --highlight-line --color=16
    
    if ($dir) {
        if ($MoveInto) {
            Set-Location $dir
            Write-Host "Changed to: $dir" -ForegroundColor Green
        }
        elseif ($Open) {
            Invoke-Item $dir -ErrorAction SilentlyContinue
        }
        elseif ($NoHyperLink) {
            Write-Host "Selected: $dir"
        }
        else {
            $esc = [char]27
            $link = "${esc}]8;;file:///$dir`a$dir${esc}]8;;`a"
            Write-Host "Selected: $link"
        }
    }
}

$helpWhich = @"
`nUsage: which [command]

Check if a command exists in PATH and show its resolved path.
"@

function which {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)][string]$Command,
        [Alias('h')][switch]$Help
    )

    if ($Help) {
        Write-Host $helpWhich
        return
    }

    if (-not $Command) {
        Write-Host $helpWhich
        return
    }

    $resolvedCommand = Get-Command $Command -ErrorAction SilentlyContinue
    if ($resolvedCommand) {
        $fullPath = $resolvedCommand.Source
        if ($fullPath) {
            Write-Host "Resolved path for " -NoNewline -ForegroundColor Gray
            Write-Host "'$Command'" -NoNewline -ForegroundColor Green
            Write-Host ":" -ForegroundColor Gray
            Write-Host ""
            Write-Host "  Name: " -NoNewline -ForegroundColor Blue
            Write-Host $resolvedCommand.Name -ForegroundColor Gray
            Write-Host "  Type: " -NoNewline -ForegroundColor Blue
            Write-Host $resolvedCommand.CommandType -ForegroundColor Gray
            Write-Host "  Path: " -NoNewline -ForegroundColor Blue
            Write-Host $fullPath -ForegroundColor Gray
        }
        else {
            Write-Host "Command '$Command' found but no source path available (built-in or alias)." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Command '$Command' not found in PATH." -ForegroundColor Red
    }
}

$helpExtract = @"
`nUsage: extract <archive> [destination]

Extract compressed archives to a destination directory.

Arguments:
  archive         Path to the archive file
  destination     Target directory (default: current directory)

Supported formats:
  .zip, .tar, .gz, .tgz, .bz2, .tar.gz, .tar.bz2, .xz, .tar.xz
  .7z, .rar

Examples:
  extract archive.zip
  extract archive.tar.gz ./extracted
  extract file.7z C:\Output

Notes:
  - Requires tar.exe for tar/zip/gz formats
  - Requires 7z.exe for 7z/rar formats
  - Creates destination directory if it doesn't exist
"@

function extract {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]$Archive,

        [Parameter(Position = 1)]
        [string]$Destination = $PWD,

        [Alias('h')]
        [switch]$Help
    )

    if ($Help) {
        Write-Host $helpExtract
        return
    }

    if (-not $Archive) {
        Write-Host $helpExtract
        return
    }

    $item = Get-Item $Archive -ErrorAction SilentlyContinue
    if (-not $item) {
        Write-Host "extract: file not found: $Archive" -ForegroundColor Red
        return
    }

    if ($item.PSIsContainer) {
        Write-Host "extract: not a file: $Archive" -ForegroundColor Red
        return
    }

    $tool = Get-ArchiveTool $item.Name
    if (-not $tool) {
        Write-Host "extract: unsupported archive: $($item.Name)" -ForegroundColor Yellow
        return
    }

    if (-not (Test-ToolAvailable $tool)) {
        Write-Host "extract: required tool not found: $tool" -ForegroundColor Yellow
        return
    }

    if (-not (Test-Path $Destination)) {
        try {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        }
        catch {
            Write-Host "extract: cannot create destination: $Destination" -ForegroundColor Red
            return
        }
    }

    try {
        switch ($tool) {
            "tar" { & tar -xf $item.FullName -C $Destination }
            "7z" { & 7z x $item.FullName "-o$Destination" -y | Out-Null }
        }
        Write-Host "Extracted: $($item.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "extract: failed: $($item.Name)" -ForegroundColor Red
    }
}

$helpCompress = @"
`nUsage: compress <path...> [options]

Compress files or directories into an archive.

Arguments:
  path...         Files or directories to compress

Options:
  -Output         Archive name (prompts if not provided)
  -Help, -h       Show this help message

Supported formats:
  .zip, .tar, .tar.gz, .tgz, .7z

Examples:
  compress folder/
  compress file1.txt file2.txt -Output backup.zip
  compress project/ -Output project.tar.gz

Notes:
  - Uses tar.exe for .zip, .tar, .tar.gz, .tgz
  - Uses 7z.exe for .7z
  - Format determined by output file extension
  - Defaults to .zip if no extension provided
"@

function compress {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Path,

        [string]$Output,

        [Alias('h')]
        [switch]$Help
    )

    if ($Help) {
        Write-Host $helpCompress
        return
    }

    if (-not $Path) {
        Write-Host $helpCompress
        return
    }

    # Validate all paths exist
    $validPaths = @()
    foreach ($p in $Path) {
        if (Test-Path $p) {
            $validPaths += (Resolve-Path $p).Path
        }
        else {
            Write-Host "compress: path not found: $p" -ForegroundColor Red
            return
        }
    }

    # Get output name if not provided
    if (-not $Output) {
        $Output = Read-Host "Archive name"
        if (-not $Output) {
            Write-Host "compress: no output name provided" -ForegroundColor Yellow
            return
        }
    }

    # Add .zip if no extension
    if (-not [System.IO.Path]::HasExtension($Output)) {
        $Output = "$Output.zip"
    }

    $tool = Get-ArchiveTool $Output
    if (-not $tool) {
        Write-Host "compress: unsupported format: $Output" -ForegroundColor Yellow
        return
    }

    if (-not (Test-ToolAvailable $tool)) {
        Write-Host "compress: required tool not found: $tool" -ForegroundColor Yellow
        return
    }

    try {
        switch ($tool) {
            "tar" {
                if ($Output -match '\.(tar\.gz|tgz)$') {
                    & tar -czf $Output @validPaths
                }
                else {
                    & tar -caf $Output @validPaths
                }
            }
            "7z" {
                & 7z a $Output @validPaths -y | Out-Null
            }
        }
        Write-Host "Created: $Output" -ForegroundColor Green
    }
    catch {
        Write-Host "compress: failed to create archive" -ForegroundColor Red
    }
}

$helpCleanup = @"
`nUsage: cleanup

Clear cache and temporary files from the system.

Clears:
  - Internet Explorer cache
  - User temporary files
  - Windows temporary files
"@

function cleanup {
    [CmdletBinding()]
    param (
        [Alias('h')]
        [switch]$Help
    )

    if ($Help) {
        Write-Host $helpCleanup
        return
    }

    function Write-Status {
        param (
            [string]$Message
        )
        Write-Host "`r$Message" -ForegroundColor DarkGray -NoNewline
        Start-Sleep -Milliseconds 300
    }

    function Remove-SafelyRecursive {
        param([string]$Path)
        Get-ChildItem -Path $Path -Recurse -Force -EA SilentlyContinue | 
        Sort-Object -Property FullName -Descending |
        ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -EA SilentlyContinue
        }
    }

    Write-Status "Clearing IE Cache"
    Remove-SafelyRecursive "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"

    Write-Status "Clearing User Temp Files"
    Remove-SafelyRecursive "$env:TEMP"

    Write-Status "Clearing Windows Temp Files"
    Remove-SafelyRecursive "$env:SystemRoot\Temp"

    Write-Host "`rCache & Temporary files have been cleared." -ForegroundColor Blue
}

$helpYank = @"
`nUsage: yank [path] [options]

Copy path, file content, or previous command to clipboard.

Options:
  -Content        Copy file contents instead of path
  -Command        Copy previous shell command from history
  -Help, -h       Show this help message

Examples:
  yank                        Copy current directory path
  yank file.txt               Copy file path
  yank -Content file.txt      Copy file contents
  yank -Command               Copy previous command
"@

function yank {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)][string]$Path = (Get-Location),
        [switch]$Content,
        [switch]$Command,
        [Alias('h')][switch]$Help
    )

    if ($Help) {
        Write-Host $helpYank
        return
    }

    if ($Command) {
        $prevCmd = (Get-History -Count 1 | Select-Object -ExpandProperty CommandLine)
        if ($null -eq $prevCmd) {
            Write-Host "No previous command found in history." -ForegroundColor Yellow
        }
        else {
            Set-Clipboard -Value $prevCmd
            Write-Host "Previous command copied to clipboard."
        }
        return
    }

    if (-not (Test-Path $Path)) {
        Write-Host "Path '$Path' does not exist." -ForegroundColor Red
        return
    }

    $FullPath = Resolve-Path -Path $Path | Select-Object -ExpandProperty Path

    if ($Content) {
        if (Test-Path $Path -PathType Container) {
            Write-Host "Cannot copy content of a directory." -ForegroundColor Yellow
            return
        }
        Set-Clipboard -Value (Get-Content -Path $FullPath -Raw)
        Write-Host "File content copied to clipboard."
        return
    }

    # Default: Copy path
    Set-Clipboard -Value $FullPath
    Write-Host "Path copied to clipboard: $FullPath"
}

$helpShank = @"
`nUsage: shank <file> [options]

Insert clipboard content into a file.

Options:
  -Replace        Overwrite file content (default: append)
  -Help, -h       Show this help message

Examples:
  shank notes.txt             Append clipboard to file
  shank -Replace config.json  Replace file with clipboard content

Notes:
  - Creates the file if it doesn't exist
  - Appends by default to avoid accidental data loss
"@

function shank {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)][string]$Path,
        [switch]$Replace,
        [Alias('h')][switch]$Help
    )

    if ($Help) {
        Write-Host $helpShank
        return
    }

    if (-not $Path) {
        Write-Host $helpShank
        return
    }

    try {
        $clipboardContent = Get-Clipboard -Raw
        if ([string]::IsNullOrEmpty($clipboardContent)) {
            Write-Host "Clipboard is empty." -ForegroundColor Yellow
            return
        }

        if ($Replace) {
            Set-Content -Path $Path -Value $clipboardContent -Force
            Write-Host "Clipboard content replaced file: $Path" -ForegroundColor Green
        }
        else {
            Add-Content -Path $Path -Value $clipboardContent -Force
            Write-Host "Clipboard content appended to: $Path" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Failed to write to '$Path': $_" -ForegroundColor Red
    }
}