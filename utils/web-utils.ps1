
$helpSearch = @"
`nUsage: search <query> [options]

Search the web using various search engines and services.

Arguments:
  query           Search query (required)

Options:
  -Service        Search engine to use (default: google)
  -Help, -h       Show this help message

Available services:
  google, googlemaps, duckduckgo, duckduckgomaps, brave, github,
  stackoverflow, scoop, winget, youtube, linkedin, chatgpt, amazon, x

Examples:
  search hello world
  search -Service github powershell scripts
  search -Service youtube music video

Notes:
  - Set DEFAULT_SEARCH_ENGINE environment variable to change default
  - Query is automatically URL-encoded
"@

$script:SearchEngines = @{
    google         = "https://www.google.com/search?q="
    googlemaps     = "https://www.google.com/maps/search/?api=1&query="
    duckduckgo     = "https://duckduckgo.com/?q="
    duckduckgomaps = "https://duckduckgo.com/?t=h_&iaxm=maps&q="
    brave          = "https://search.brave.com/search?q="
    github         = "https://github.com/search?q="
    stackoverflow  = "https://stackoverflow.com/search?q="
    scoop          = "https://scoop.sh/#/apps?q="
    winget         = "https://winget.run/search?query="
    youtube        = "https://www.youtube.com/results?search_query="
    linkedin       = "https://www.linkedin.com/search/results/all/?keywords="
    chatgpt        = "https://chat.openai.com/?q="
    amazon         = "https://www.amazon.in/s?k="
    x              = "https://twitter.com/search?q="
}

function search {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Query,

        [ValidateSet(
            'google', 'googlemaps', 'duckduckgo', 'duckduckgomaps', 'brave',
            'github', 'stackoverflow', 'scoop', 'winget', 'youtube',
            'linkedin', 'chatgpt', 'amazon', 'x'
        )]
        [string]$Service,

        [Alias('h')]
        [switch]$Help
    )

    if ($Help) {
        Write-Host $helpSearch
        return
    }

    if (-not $Query) {
        Write-Host $helpSearch
        return
    }

    # Determine which service to use
    $selectedService = if ($Service) {
        $Service
    }
    elseif ($env:DEFAULT_SEARCH_ENGINE -and $script:SearchEngines.ContainsKey($env:DEFAULT_SEARCH_ENGINE)) {
        $env:DEFAULT_SEARCH_ENGINE
    }
    else {
        "google"
    }

    # Build search URL
    $searchQuery = $Query -join " "
    $url = $script:SearchEngines[$selectedService] + [uri]::EscapeDataString($searchQuery)

    Write-Host "Searching '$searchQuery' on $selectedService..." -ForegroundColor DarkGray
    Start-Process $url
}

# fetch - Download a file from a web URL
# vidl - Download a video from a YouTube URL
# trdl - Download a torrent or magnet link

$helpWebCheck = @"
`nUsage: webcheck <url> [options]

Inspect a web URL and display metadata.

Arguments:
  url             URL to inspect

Options:
  -Verbose        Show response headers
  -Help, -h       Show this help message

Examples:
  webcheck https://example.com
  webcheck https://example.com/file.zip -Verbose

Information shown:
  - HTTP status code
  - Final URL (after redirects)
  - Content type
  - File size
  - Resume support (partial downloads)
  - Last modified date
"@

function webcheck {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]$Url,

        [Alias('h')]
        [switch]$Help
    )

    if ($Help) {
        Write-Host $helpWebCheck
        return
    }

    if (-not $Url) {
        Write-Host $helpWebCheck
        return
    }

    # Validate URL format
    if ($Url -notmatch '^https?://') {
        Write-Host "webcheck: invalid URL (must start with http:// or https://)" -ForegroundColor Red
        return
    }

    try {
        $response = Invoke-WebRequest `
            -Uri $Url `
            -Method Head `
            -MaximumRedirection 10 `
            -TimeoutSec 15 `
            -ErrorAction Stop
    }
    catch {
        Write-Host "`nwebcheck: request failed" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        return
    }

    $headers = $response.Headers
    $status = $response.StatusCode

    $type = $headers["Content-Type"] | Select-Object -First 1
    $lengthHeader = $headers["Content-Length"] | Select-Object -First 1
    $ranges = $headers["Accept-Ranges"] | Select-Object -First 1
    $modified = $headers["Last-Modified"] | Select-Object -First 1
    $server = $headers["Server"] | Select-Object -First 1

    Write-Host "`nWeb Check Results:" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "URL:        " -NoNewline -ForegroundColor Blue
    Write-Host $Url -ForegroundColor Gray
    
    Write-Host "Status:     " -NoNewline -ForegroundColor Blue
    if ($status -ge 200 -and $status -lt 300) {
        Write-Host $status -ForegroundColor Green
    }
    elseif ($status -ge 300 -and $status -lt 400) {
        Write-Host $status -ForegroundColor Yellow
    }
    else {
        Write-Host $status -ForegroundColor Red
    }

    if ($type) {
        Write-Host "Type:       " -NoNewline -ForegroundColor Blue
        Write-Host $type -ForegroundColor Gray
    }

    if ($lengthHeader) {
        $lengthBytes = [int64]$lengthHeader
        if ($lengthBytes -gt 1GB) {
            $size = [math]::Round($lengthBytes / 1GB, 2)
            $unit = "GB"
        }
        elseif ($lengthBytes -gt 1MB) {
            $size = [math]::Round($lengthBytes / 1MB, 2)
            $unit = "MB"
        }
        elseif ($lengthBytes -gt 1KB) {
            $size = [math]::Round($lengthBytes / 1KB, 2)
            $unit = "KB"
        }
        else {
            $size = $lengthBytes
            $unit = "bytes"
        }
        Write-Host "Size:       " -NoNewline -ForegroundColor Blue
        Write-Host "$size $unit" -ForegroundColor Gray
    }
    else {
        Write-Host "Size:       " -NoNewline -ForegroundColor Blue
        Write-Host "unknown" -ForegroundColor Gray
    }

    Write-Host "Resume:     " -NoNewline -ForegroundColor Blue
    if ($ranges -eq "bytes") {
        Write-Host "yes" -ForegroundColor Green
    }
    else {
        Write-Host "no" -ForegroundColor Yellow
    }

    if ($modified) {
        Write-Host "Modified:   " -NoNewline -ForegroundColor Blue
        Write-Host $modified -ForegroundColor Gray
    }

    if ($server) {
        Write-Host "Server:     " -NoNewline -ForegroundColor Blue
        Write-Host $server -ForegroundColor Gray
    }

    # Show all headers if verbose
    if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
        Write-Host "`nResponse Headers:" -ForegroundColor Blue
        foreach ($key in $headers.Keys) {
            $value = $headers[$key] -join ", "
            Write-Host "  $key`: " -NoNewline -ForegroundColor DarkGray
            Write-Host $value -ForegroundColor Gray
        }
    }
}

