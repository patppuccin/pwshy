

function Set-PSReadlineConfiguration {
    param (
        [Parameter(Mandatory = $false)]
        [string]$PaletteName
    )

    if (-not (Get-Module -ListAvailable -Name PSReadLine)) {
        return "PSReadLine module not found (install with 'Install-Module PSReadLine -Scope CurrentUser')"
    }


    # Import PSReadLine module
    Import-Module PSReadLine

    # Enhanced PSReadLine Configuration
    $PSReadLineOptions = @{
        EditMode                      = 'Windows'
        HistoryNoDuplicates           = $true
        HistorySearchCursorMovesToEnd = $true
        Colors                        = @{
            Command                = $Catppuccin.mauve     # Mauve for commands
            Parameter              = $Catppuccin.green     # Green for parameters
            Operator               = $Catppuccin.peach     # Peach for operators
            Variable               = $Catppuccin.yellow    # Yellow for variables
            String                 = $Catppuccin.rosewater # Rosewater for strings
            Number                 = $Catppuccin.sky       # Sky for numbers
            Type                   = $Catppuccin.blue      # Blue for types
            Comment                = $Catppuccin.overlay1  # Subdued overlay for comments
            Keyword                = $Catppuccin.pink      # Pink for keywords
            Error                  = $Catppuccin.red       # Red for errors (high visibility)
            ListPrediction         = $Catppuccin.overlay0  # Color for prediction list items
            ListPredictionSelected = "`e[48;2;76;61;86m"   # Blended Mauve
            ListPredictionTooltip  = $Catppuccin.mauve     # Color for prediction tooltips
            Selection              = "`e[48;2;76;61;86m"   # Blended Mauve
        }
        PredictionSource              = 'History'
        PredictionViewStyle           = 'ListView'
        ShowToolTips                  = $true  
        BellStyle                     = 'None'
    }

    Set-PSReadLineOption @PSReadLineOptions
    
    # Custom key handlers
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

    # Custom functions for PSReadLine
    Set-PSReadLineOption -AddToHistoryHandler {
        param($line)
        $sensitive = @('password', 'secret', 'token', 'apikey', 'connectionstring')
        $hasSensitive = $sensitive | Where-Object { $line -match $_ }
        return ($null -eq $hasSensitive)
    }

    # Improved prediction settings
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -MaximumHistoryCount 10000
    
}