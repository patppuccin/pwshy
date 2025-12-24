# Module root
$ModuleRoot = $PSScriptRoot

# Script directories
$PrivateDirs = @(
    'helpers'
)

$PublicDirs = @(
    'utils',
    'plugins'
)


# Load private scripts
foreach ($Dir in $PrivateDirs) {
    $Path = Join-Path $ModuleRoot $Dir
    if (-not (Test-Path $Path)) { continue }
    
    Get-ChildItem $Path -Filter '*.ps1' -Recurse -File |
    ForEach-Object {
        . $_.FullName
    }
}

# Load public scripts
$script:FilesToExport = @()

# Track the files to be exported
foreach ($dir in $PublicDirs) {
    $Path = Join-Path $ModuleRoot $dir
    if (-not (Test-Path $Path)) { continue }

    Get-ChildItem $Path -Filter '*.ps1' -Recurse -File |
    ForEach-Object {
        . $_.FullName
        $script:FilesToExport += $_.FullName
    }
}

# Export public functions
$ExportedFunctions = Get-Command -CommandType Function |
Where-Object {
    $_.ScriptBlock.File -and
    $script:FilesToExport -contains $_.ScriptBlock.File
}

Export-ModuleMember -Function $ExportedFunctions.Name
