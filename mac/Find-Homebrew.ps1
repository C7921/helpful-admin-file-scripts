#!/usr/bin/env pwsh

# Function to locate Homebrew and ensure it's in the PATH
function Find-Homebrew {
  # Common Homebrew locations
  $homebrewPaths = @(
    "/usr/local/bin/brew", # Intel Macs (older installation)
    "/opt/homebrew/bin/brew", # Apple Silicon Macs
    "$HOME/homebrew/bin/brew", # Custom user installation
    "/home/linuxbrew/.linuxbrew/bin/brew"  # Linux
  )
    
  $brewPath = $null
    
  # Check each path to see if brew exists there
  foreach ($path in $homebrewPaths) {
    if (Test-Path $path) {
      $brewPath = Split-Path -Parent $path
      Write-Host "Found Homebrew at: $brewPath" -ForegroundColor Green
      break
    }
  }
    
  # If not found in common locations, try using 'which'
  if (-not $brewPath) {
    try {
      $whichBrew = & which brew 2>&1
      if ($LASTEXITCODE -eq 0 -and $whichBrew) {
        $brewPath = Split-Path -Parent $whichBrew
        Write-Host "Found Homebrew at: $brewPath (via which)" -ForegroundColor Green
      }
    }
    catch {
      # Continue if 'which' command isn't available
    }
  }
    
  # Add to PATH if found
  if ($brewPath) {
    if (-not $env:PATH.Contains($brewPath)) {
      $env:PATH += ":$brewPath"
      Write-Host "Added Homebrew to PATH: $brewPath" -ForegroundColor Yellow
    }
    else {
      Write-Host "Homebrew already in PATH" -ForegroundColor Cyan
    }
    return $true
  }
  else {
    Write-Host "Homebrew not found. Please install Homebrew or add it to your PATH." -ForegroundColor Red
    return $false
  }
}

# Run the function to find Homebrew
Find-Homebrew