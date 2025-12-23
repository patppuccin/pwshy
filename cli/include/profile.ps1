# ==== PowerShell Profile Configuration ====================

# ==== Prepare Environment =================================

$startupLogs = @()
$loadedTools = @()
$missingTools = @()

$PSStyle.FileInfo.Directory = "" # Disable Directory Highlights (PowerShell versions > 7.3)

# ==== Setup Tools Listing =================================

$Tools = @(
    [ordered]@{  Name = 'starship'; Repo = 'https://github.com/starship/starship' },
    [ordered]@{  Name = 'bat'; Repo = 'https://github.com/sharkdp/bat' },
    [ordered]@{  Name = 'fzf'; Repo = 'https://github.com/junegunn/fzf' },
    [ordered]@{  Name = 'zoxide'; Repo = 'https://github.com/ajeetdsouza/zoxide' },
    [ordered]@{  Name = 'git' ; Repo = 'https://github.com/git/git' },
    [ordered]@{  Name = 'kubectl'; Repo = 'https://github.com/kubernetes/kubernetes' }

) | ForEach-Object { [PSCustomObject]$_ }

foreach ($tool in $Tools) {
    if (-not (Get-Command $tool.Name -ErrorAction SilentlyContinue)) {
        $missingTools += $tool
    }
    else {
        $loadedTools += $tool
    }
}

$startupLogs += "Failed to load tools: $($missingTools.Name -join ', ')"

# === Load Utils & Plugins =================================

$pwshyRoot = Join-Path $HOME '.pwshy'
Get-ChildItem (Join-Path $pwshyRoot 'utils') -Filter *.ps1 -Recurse | ForEach-Object { . $_.FullName }
Get-ChildItem (Join-Path $pwshyRoot 'plugins') -Filter *.ps1 -Recurse | ForEach-Object { . $_.FullName }

# ==== Load Tools ==========================================

if ('starship' -in $loadedTools.Name) {
    $ENV:STARSHIP_CONFIG = "$ENV:USERPROFILE/.config/starship/starship.toml"
    Invoke-Expression (&starship init powershell)
}

if ('fastfetch' -in $loadedTools.Name) {
    & fastfetch.exe
}

if ('zoxide' -in $loadedTools.Name) {
    Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
}

# ==== Load Environment Variables ==========================

$env:UV_LINK_MODE = 'copy'