<#
.SYNOPSIS
    Update file timestamps or create new files.

.DESCRIPTION
    A PowerShell implementation of the Unix 'touch' command. 
    It creates one or more files if they do not exist. 
    If a file already exists, it updates its 'LastWriteTime' property to the current system time.

.PARAMETER Path
    Specifies the path to one or more files. This parameter accepts pipeline input and wildcards.

.PARAMETER Help
    Shows the help documentation for this function.

.EXAMPLE
    touch file.txt
    Creates 'file.txt' if it doesn't exist; otherwise, updates its timestamp.

.EXAMPLE
    touch a.txt, b.txt, c.txt
    Touches multiple files passed as a comma-separated list.

.EXAMPLE
    'file1.txt','file2.txt' | touch
    Accepts file paths from the pipeline.

.INPUTS
    System.String[]. You can pipe an array of strings representing file paths to this function.

.OUTPUTS
    None. This function does not return any objects to the pipeline unless -PassThru is implemented.

.LINK
    https://github.com/patppuccin/pwshy
#>
function touch {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromRemainingArguments)]
        [string[]]$Path,

        [Alias('h')]
        [switch]$Help
    )

    begin {
        if ($Help -or $Path -contains '--help') { $MyInvocation.MyCommand | Get-Help; break }
    }

    process {
        if (-not $Path) {
            $MyInvocation.MyCommand | Get-Help
            return
        }

        foreach ($p in $Path) {
            try {
                if (Test-Path $p) {
                    (Get-Item $p).LastWriteTime = Get-Date
                }
                else {
                    $null = New-Item -ItemType File -Path $p -Force
                }
            }
            catch {
                Write-Warning "touch: failed for '$p' - $($_.Exception.Message)"
            }
        }
    }
}