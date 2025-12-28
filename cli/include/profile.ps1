# ==== PowerShell Profile Configuration ====================

# ==== Check for Minimum PowerShell Version ===============

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "PowerShell version 7 of higher required for this configuration"
    Write-Host ""
    Write-Host " - This profile is located at $($PROFILE)"
    Write-Host " - PowerShell 7 can be installed via https://aka.ms/install-powershell"
    Write-Host ""
    return
}

# ==== Prepare Environment =================================

$StartupLogs = @()
$LoadedTools = @()
$MissingTools = @()

$ConfigRoot = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
$PwshKitRoot = Join-Path $ConfigRoot 'pwshkit' 'pwshkit.psm1'

$PSStyle.FileInfo.Directory = "" # Disable Directory Highlights (PowerShell versions > 7.3)

# ==== Setup Tools Listing =================================

$Tools = @('starship', 'bat', 'fzf', 'zoxide', 'git', 'fastfetch', 'kubectl')

foreach ($Tool in $Tools) {
    if (-not (Get-Command $Tool -ErrorAction SilentlyContinue)) {
        $MissingTools += $Tool
    }
    else {
        $LoadedTools += $Tool
    }
}

if ($MissingTools.Count -gt 0) {
    $StartupLogs += "Missing tools: $($MissingTools -join ', ')"
}

# === Load Pwshkit Utils & Plugins =========================

if (Test-Path $PwshKitRoot) {
    try { Import-Module $PwshKitRoot -ErrorAction Stop }
    catch { $StartupLogs += "Failed to load pwshkit: $($_.Exception.Message)" }
}
else {
    $StartupLogs += "Pwshkit not found at: $PwshKitRoot"
}

# ==== Setup PSReadline ====================================

if (-not (Get-Module -ListAvailable -Name PSReadLine)) {

    # Import PSReadLine module
    Import-Module PSReadLine

    # Features Configuration
    Set-PSReadLineOption @{
        EditMode                      = 'Windows'
        HistoryNoDuplicates           = $true
        HistorySearchCursorMovesToEnd = $true
        PredictionSource              = 'HistoryAndPlugin'
        PredictionViewStyle           = 'ListView'
        ShowToolTips                  = $true  
        BellStyle                     = 'None'
        MaximumHistoryCount           = 10000
    }

    Set-PSReadLineOption -AddToHistoryHandler {
        param($line)
        $line -notmatch '(password|secret|token|apikey|connectionstring)'
    }

    # Key Handlers Configuration
    Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Chord 'Ctrl+a' -Function BeginningOfLine
    Set-PSReadLineKeyHandler -Chord 'Ctrl+e' -Function EndOfLine
    Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow'  -Function BackwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
    Set-PSReadLineKeyHandler -Chord 'Alt+d'  -Function DeleteWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+k' -Function KillLine
    Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Yank
    Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -Function ReverseSearchHistory
    Set-PSReadLineKeyHandler -Chord 'Ctrl+l' -Function ClearScreen
    Set-PSReadLineKeyHandler -Key RightArrow -Function AcceptNextSuggestionWord

}

# ==== Load Tools ==========================================

if ('starship' -in $LoadedTools.Name) {
    $ENV:STARSHIP_CONFIG = Join-Path $ConfigRoot 'starship' 'starship.toml'
    try { Invoke-Expression (&starship init powershell) }
    catch { $StartupLogs += "Failed to initialize starship" }
}

if ('fastfetch' -in $LoadedTools.Name) {
    & fastfetch
}

if ('zoxide' -in $LoadedTools.Name) {
    try { Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) }) } 
    catch { $StartupLogs += "Failed to initialize zoxide" }
}

# ==== Load Environment Variables ==========================

$env:UV_LINK_MODE = 'copy'