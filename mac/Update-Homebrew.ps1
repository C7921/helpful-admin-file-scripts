#! usr/bin/env pwsh

# Make sure Homebrew is in path
$env:PATH += ":/usr/local/bin:/opt/homebrew/bin"
function Update-HomeBrew {
  [CmdletBinding()]
  param (
    [switch]$UpgradeAll,
    [switch]$Cleanup,
    [switch]$ShowOutdated
  )

  Write-Host "🍺 Starting Homebrew update and upgrade process..." -ForegroundColor Cyan

  # Check if Homebrew is installed
  if (!(Get-Command brew -ErrorAction SilentlyContinue)) {
    Write-Host "Homebrew is not installed or in PATH. Please install Homebrew first." -ForegroundColor Red
    return
  }

  try {
    # Update Homebrew
    Write-Host "Updating Homebrew..." -ForegroundColor Green
    $updateOutput = $(brew update)
    Write-Host $updateOutput -ForegroundColor Green
    Write-Host "✅ Homebrew updated successfully." -ForegroundColor Green

    # Show outdated packages
    if ($ShowOutdated) {
      Write-Host "🔍 Checking for outdated packages..." -ForegroundColor Yellow
      $outdatedPackages = $(brew outdated) 2>&1

      if ($outdatedPackages) {
        Write-Host "The following packages are outdated:" -ForegroundColor Magenta
        Write-Host $outdatedPackages -ForegroundColor Gray
      }
      else {
        Write-Host "All packages are up to date. 🎉" -ForegroundColor Green  
      }
    }

    # Upgrade all packages
    if ($UpgradeAll) {
      Write-Host "🔄 Upgrading all packages..." -ForegroundColor Yellow
      $upgradeOutput = $(brew upgrade) 2>&1
      Write-Host $upgradeOutput -ForegroundColor Gray
      Write-Host "✅ All packages upgraded successfully." -ForegroundColor Green
    }

    # Cleanup
    if ($Cleanup) {
      Write-Host "🧹 Cleaning up older versions..." -ForegroundColor Yellow
      $cealnupOutput = $(brew cleanup) 2>&1
      Write-Host $cealnupOutput -ForegroundColor Gray
      Write-Host "✅ Cleanup completed successfully." -ForegroundColor Green
    }

    #Get Homebrew info
    $brewInfo = $(brew info --json=v1 --installed) | ConvertFrom-Json
    $totalPackages = $brewInfo.Count
    $totalSize = [Math]::Round(($brewInfo | Measure-Object -Property installed_on_request -Sum).Sum / 1024 / 1024, 2)

    # Print Summary
    Write-Host "📊 Homebrew Summary:" -ForegroundColor Cyan
    Write-Host "📦 Total packages installed: $totalPackages" -ForegroundColor White
    Write-Host "📏 Total size of installed packages: $totalSize MB" -ForegroundColor White
  }
  catch {
    Write-Host "❌ An error occurred: $_" -ForegroundColor Red
  }
  finally {
    Write-Host "🍺 Homebrew update and upgrade process completed." -ForegroundColor Green
  }
}

# Usage
# Update Homebrew: Update-Homebrew
# Update and show outdated packages: Update-Homebrew -ShowOutdated
# Full update, upgrade and cleanup: Update-Homebrew -UpgradeAll -Cleanup -ShowOutdated
Update-Homebrew -ShowOutdated
