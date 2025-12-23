# Tool Setup for Zoxide
if (Test-ToolExistenceAndLog 'zoxide') {
    Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
}

