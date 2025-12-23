# <pwshy-managed-block>
# PWSHY: PowerShell with Superpowers
# Documentation: https://github.com/patppuccin/pwshy

$env:PWSHY_ROOT = "$($HOME)\.pwshy"

if (Test-Path "$env:PWSHY_ROOT\pwshy.psm1") {
    Import-Module "$env:PWSHY_ROOT\pwshy.psm1" -Force
}
else {
    Write-Warning "pwshy root not found at $env:PWSHY_ROOT. Please check your installation."
}
# </pwshy-managed-block>

# --- User Customizations Below This Line ---
# Any personal aliases or scripts you want to keep separate from pwshy.