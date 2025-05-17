# Mac Homebrew Powershell Scripts


## Find-Homebrew

Finds and verifies homebrew install location, and if found, adds to PATH.

## Manage Homewbrew Packages

Checks Homebrew is in PATH.
Run with default params`Get-HomebrewPackages`
Creates summary of packages and casks installed.


## Update Homebrew

Can list and update homebrew packages and casks.


``` powershell
# Usage
# Update Homebrew: Update-Homebrew
# Update and show outdated packages: Update-Homebrew -ShowOutdated
# Full update, upgrade and cleanup: Update-Homebrew -UpgradeAll -Cleanup -ShowOutdated
Update-Homebrew -ShowOutdated
```
