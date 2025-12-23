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

function Test-ToolExistenceAndLog { 
    param(
        [Parameter(Mandatory = $true)]
        [string]$tool
    )
    
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        return $true
    }
    else {
        $StartupLogs += "tool unavailable: $tool"
        return $false
    }
}