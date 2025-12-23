# ==== Global Variables ====================================
$InitLogs = @()
$ThemePaletteName = "catppuccin-mocha"

# ==== Helper Functions ====================================
function Import-IfExists {
    param ([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) {
        return $false
    }

    if (Test-Path $Path -PathType Leaf) {
        . $Path
        return $true
    }

    if (Test-Path $Path -PathType Container) {
        Get-ChildItem $Path -Filter "*.ps1" -File | Sort-Object Name | ForEach-Object { . $_.FullName }
        return $true
    }

    return $false
}

# ==== Configurations Entrypoint ===========================

# Setup theming
$ThemesFile = Join-Path $PSScriptRoot "themes\theme.ps1"
if (Import-IfExists $ThemesFile) {
    $Palette = Get-ThemePalette -PaletteName $ThemePaletteName
}
else {
    $InitLogs += "Could not find $ThemesFile"
}

# Setup PowerShell default highlights
$PSStyle.FileInfo.Directory = ""

# Setup PSReadLine
$PSReadlineFile = Join-Path $PSScriptRoot "utils\readline.ps1"
if (Import-IfExists $PSReadlineFile) {
    $InitLogs += Set-PSReadlineConfiguration -Palette $Palette
}
else {
    $InitLogs += "Could not find $PSReadlineFile"
}

# Load utility functions 


# Load environment variables
$EnvFile = Join-Path $PSScriptRoot "env"
if (Import-IfExists $EnvFile) {
    $InitLogs += "Loaded $EnvFile"
}
else {
    $InitLogs += "Could not find $EnvFile"
}