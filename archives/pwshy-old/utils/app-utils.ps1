# ==== Util 01: File Editor ================================
function Open-Editor {
    [CmdletBinding()]
    param ([Parameter(Position = 0)][string]$Path = ".")

    $editorName = $Script:Config.Editor

    if (-not $editorName) {
        Write-Host "No editor configured." -ForegroundColor Yellow
        Write-Host "Run 'pwshy config' to set one." -ForegroundColor DarkGray
        return
    }

    $editor = Get-Command $editorName -ErrorAction SilentlyContinue
    if (-not $editor) {
        Write-Host "Configured editor '$editorName' not found in PATH." -ForegroundColor Red
        Write-Host "Run 'pwshy config' to update it." -ForegroundColor DarkGray
        return
    }

    try {
        $resolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
        Write-Host "Opening '$resolvedPath' with '$editorName'." -ForegroundColor Green
        & $editor.Name $resolvedPath
    }
    catch {
        Write-Host "Could not resolve path to '$Path'" -ForegroundColor Yellow
    }
}

Set-Alias -Name edit -Value Open-Editor

# ==== Util 02: File Opener ================================
function Open-File {
    [CmdletBinding()]
    param ([Parameter(Position = 0)][string]$Path = ".")

    try {
        $resolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
        $baseName = Split-Path -Path $resolvedPath -Leaf
        Write-Host "Opening '$baseName'." -ForegroundColor Gray
        Start-Process -FilePath $resolvedPath
    }
    catch {
        Write-Host "Could not resolve path to '$Path'" -ForegroundColor Yellow
    }
}

Set-Alias -Name open -Value Open-File
