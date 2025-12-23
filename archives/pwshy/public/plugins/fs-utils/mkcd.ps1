<#
.SYNOPSIS
    Create a directory and change into it.

.DESCRIPTION
    Creates a directory if it does not exist and sets the current location to it.

.PARAMETER Dir
    The path of the directory to create and enter.

.PARAMETER Help
    Shows the help documentation for this function.

.EXAMPLE
    mkcd myfolder
    Creates 'myfolder' and sets the location to it.

.LINK
    https://github.com/patppuccin/pwshy
#>
function mkcd {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]$Dir,

        [Alias('h')]
        [switch]$Help
    )

    if ($Help -or ($Dir -match '^-{1,2}help$')) {
        $MyInvocation.MyCommand | Get-Help
        return
    }

    try {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
        Set-Location -Path $Dir
    }
    catch {
        Write-Warning "mkcd: Failed to create or move into '$Dir'."
    }
}