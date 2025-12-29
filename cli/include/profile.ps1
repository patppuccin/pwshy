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
    if (Get-Command $Tool -ErrorAction SilentlyContinue) {
        $LoadedTools += $Tool
    }
    else {
        $MissingTools += $Tool
    }
}

if ($MissingTools.Count -gt 0) {
    $StartupLogs += "Missing tools: $($MissingTools -join ', ')"
}

# ==== Load Pwshkit Utils & Plugins =========================

if (Test-Path $PwshKitRoot) {
    try { Import-Module $PwshKitRoot -ErrorAction Stop }
    catch { $StartupLogs += "Failed to load pwshkit: $($_.Exception.Message)" }
}
else {
    $StartupLogs += "Pwshkit not found at: $PwshKitRoot"
}

# ==== Setup PSReadLine ====================================

if ($Host.Name -eq 'ConsoleHost') {

    Import-Module PSReadLine -ErrorAction SilentlyContinue

    if (Get-Module PSReadLine) {

        $PSReadlineConfigOptions = @{
            EditMode                      = 'Windows'
            HistoryNoDuplicates           = $true
            HistorySearchCursorMovesToEnd = $true
            PredictionSource              = 'HistoryAndPlugin'
            PredictionViewStyle           = 'ListView'
            ShowToolTips                  = $true
            BellStyle                     = 'None'
            MaximumHistoryCount           = 10000
        }

        Set-PSReadLineOption @PSReadlineConfigOptions

        Set-PSReadLineOption -Colors @{
            Command                = 'Magenta'     # Mauve
            Parameter              = 'Green'       # Green
            Operator               = 'DarkYellow'  # Peach
            Variable               = 'Yellow'      # Yellow
            String                 = 'White'       # Rosewater
            Number                 = 'Cyan'        # Sky
            Type                   = 'Blue'        # Blue
            Comment                = 'DarkGray'    # Overlay1
            Keyword                = 'Magenta'     # Pink
            Error                  = 'Red'         # Red
        
            ListPrediction         = 'DarkGray'    # Overlay0
            ListPredictionSelected = 'DarkMagenta' # Muted Mauve feel
            ListPredictionTooltip  = 'Magenta'     # Mauve
            Selection              = 'DarkMagenta' # Theme-backed selection
        }
        
        Set-PSReadLineOption -AddToHistoryHandler {
            param($line)
            $line -notmatch '(password|secret|token|apikey|connectionstring)'
        }

        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
        Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
        Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
        Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
        Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
        Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
        Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo
    }
}

# ==== Load Tools ==========================================

if ('starship' -in $LoadedTools) {
    $ENV:STARSHIP_CONFIG = Join-Path $ConfigRoot 'starship' 'starship.toml'
    try { Invoke-Expression (& starship init powershell) }
    catch { $StartupLogs += "Failed to initialize starship" }
}

if ('fastfetch' -in $LoadedTools) {
    & fastfetch
}

if ('zoxide' -in $LoadedTools) {
    try { Invoke-Expression (& { zoxide init --cmd cd powershell | Out-String }) }
    catch { $StartupLogs += "Failed to initialize zoxide" }
}

# ==== Load Environment Variables ==========================

$env:UV_LINK_MODE = 'copy'
