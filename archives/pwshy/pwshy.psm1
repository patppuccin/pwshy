# $PWSHY_ROOT = $PSScriptRoot
# $PWSHY_CONFIG = if ($env:XDG_CONFIG_HOME) { "$($env:XDG_CONFIG_HOME)/pwshy" } else { "$HOME/.config/pwshy" }



# -------------------------------
# Module startup state
# -------------------------------

$script:StartupLogs = @()
$script:LoadedPublicFiles = @()

$privatePath = Join-Path $PSScriptRoot 'private'

if (Test-Path $privatePath) {
    Get-ChildItem $privatePath -Filter *.ps1 -Recurse |
    Sort-Object FullName |
    ForEach-Object {
        . $_.FullName
    }
}

$publicPath = Join-Path $PSScriptRoot 'public'

if (Test-Path $publicPath) {
    Get-ChildItem $publicPath -Filter *.ps1 -Recurse |
    Sort-Object FullName |
    ForEach-Object {
        . $_.FullName
        $script:LoadedPublicFiles += (Resolve-Path $_.FullName).Path
    }
}

# === Load Tools ===========================================

# Tool setup for Starship
if (Test-ToolExistenceAndLog 'starship') {
    $ENV:STARSHIP_CONFIG = "$ENV:USERPROFILE/.config/starship/starship.toml"
    Invoke-Expression (&starship init powershell)
}

# Tool setup for bat
if (Test-ToolExistenceAndLog 'bat') {
    $ENV:BAT_CONFIG_PATH = "$ENV:USERPROFILE/.config/bat/bat.conf"
    $ENV:BAT_CONFIG_DIR = "$ENV:USERPROFILE/.config/bat"
    Set-Alias -Name cat -Value bat
}

# Tool setup for fzf
Test-ToolExistenceAndLog 'fzf'

# Tool Setup for Zoxide
if (Test-ToolExistenceAndLog 'zoxide') {
    Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
}

$exportedFunctions = Get-Command -Module pwshy -CommandType Function |
Where-Object {
    $_.ScriptBlock.File -and
    $script:LoadedPublicFiles -contains $_.ScriptBlock.File
}

Export-ModuleMember -Function $exportedFunctions.Name
