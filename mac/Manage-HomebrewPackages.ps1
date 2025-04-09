#!/usr/bin/env pwsh

# Ensure Homebrew is in the PATH
$env:PATH += ":/usr/local/bin:/opt/homebrew/bin"

function Get-HomebrewPackages {
  [CmdletBinding()]
  param (
    [switch]$Casks,
    [switch]$Formulae,
    [switch]$Detailed
  )

  Write-Host "🍺 Analyzing Homebrew packages..." -ForegroundColor Cyan

  # Check if Homebrew is installed
  if (!(Get-Command brew -ErrorAction SilentlyContinue)) {
    Write-Error "Homebrew is not installed or not in PATH."
    return
  }

  try {
    # Create output collections
    $formulaeList = @()
    $casksList = @()

    # Process formulae
    if (!$Casks -or $Formulae) {
      Write-Host "  Getting formulae information..." -ForegroundColor Yellow
            
      # Get all installed packages in JSON format with debugging
      try {
        $allPackagesJson = $(brew info --json=v1 --installed) 2>&1
                
        # Check if we have valid JSON
        $allPackages = $allPackagesJson | ConvertFrom-Json
        Write-Host "  Successfully parsed package JSON data" -ForegroundColor Green
                
        # Process formulae information
        foreach ($package in $allPackages) {
          $name = $package.name
                    
          # Handle potential missing or null values
          $version = if ($package.installed -and $package.installed.Count -gt 0 -and $null -ne $package.installed[0].version) {
            $package.installed[0].version
          }
          else { "Unknown" }
                    
          $size = if ($package.installed -and $package.installed.Count -gt 0 -and $null -ne $package.installed[0].installed_on_request) {
            [Math]::Round($package.installed[0].installed_on_request / 1024 / 1024, 2)
          }
          else { 0 }
                    
          $desc = if ($null -ne $package.desc) { $package.desc } else { "No description available" }

          $packageObj = [PSCustomObject]@{
            Name        = $name
            Version     = $version
            "Size (MB)" = $size
            Description = $desc
          }

          if ($Detailed) {
            $packageObj | Add-Member -MemberType NoteProperty -Name "Dependencies" -Value ($package.dependencies -join ", ")
            if ($package.installed -and $package.installed.Count -gt 0 -and $null -ne $package.installed[0].time) {
              $packageObj | Add-Member -MemberType NoteProperty -Name "Install Date" -Value $package.installed[0].time
            }
          }

          $formulaeList += $packageObj
        }
      }
      catch {
        Write-Warning "Error processing formulae: $_"
      }
    }

    # Process casks - using a different, more reliable approach
    if (!$Formulae -or $Casks) {
      Write-Host "  Getting casks information..." -ForegroundColor Yellow
            
      try {
        # Simply list all casks
        $allCasks = $(brew list --cask) 2>&1
                
        if ($allCasks) {
          Write-Host "  Found $($allCasks.Count) casks" -ForegroundColor Green
                    
          # Process each cask with a safer approach
          foreach ($cask in $allCasks) {
            try {
              # Get minimal info about the cask to avoid parsing issues
              $caskObj = [PSCustomObject]@{
                Name        = $cask
                Version     = "Installed"  # Default value
                Description = "Installed cask"  # Default description
              }
                            
              # Try to get more info if needed
              if ($Detailed) {
                # We'll use a safer approach to get version
                $info = $(brew info --cask $cask --json=v1) 2>&1
                try {
                  $jsonInfo = $info | ConvertFrom-Json
                  if ($jsonInfo -and $jsonInfo[0].version) {
                    $caskObj.Version = $jsonInfo[0].version
                  }
                  if ($jsonInfo -and $jsonInfo[0].desc) {
                    $caskObj.Description = $jsonInfo[0].desc
                  }
                }
                catch {
                  # If JSON parsing fails, just continue with default values
                  Write-Verbose "Could not parse JSON for cask $cask"
                }
              }
                            
              $casksList += $caskObj
            }
            catch {
              Write-Warning "Error processing cask $cask`: $_"
                            
              # Add with minimal info
              $casksList += [PSCustomObject]@{
                Name        = $cask
                Version     = "Error"
                Description = "Error retrieving information"
              }
            }
          }
        }
        else {
          Write-Host "  No casks found" -ForegroundColor Yellow
        }
      }
      catch {
        Write-Warning "Error listing casks: $_"
      }
    }

    # Output results based on parameters
    if ((!$Casks -and !$Formulae) -or ($Casks -and $Formulae)) {
      # Show both formulae and casks
      Write-Host "📦 Formulae ($($formulaeList.Count) packages):" -ForegroundColor Yellow
      if ($formulaeList.Count -gt 0) {
        $formulaeList | Format-Table -AutoSize
      }
      else {
        Write-Host "   No formulae found" -ForegroundColor Gray
      }

      Write-Host "🖥️ Casks ($($casksList.Count) applications):" -ForegroundColor Yellow
      if ($casksList.Count -gt 0) {
        $casksList | Format-Table -AutoSize
      }
      else {
        Write-Host "   No casks found" -ForegroundColor Gray
      }

      Write-Host "📊 Summary:" -ForegroundColor Cyan
      Write-Host "Total Formulae: $($formulaeList.Count)" -ForegroundColor White
      Write-Host "Total Casks: $($casksList.Count)" -ForegroundColor White
      Write-Host "Total Packages: $($formulaeList.Count + $casksList.Count)" -ForegroundColor White

      if ($formulaeList.Count -gt 0) {
        $totalSize = ($formulaeList | Measure-Object -Property "Size (MB)" -Sum).Sum
        Write-Host "Total Size: $totalSize MB" -ForegroundColor White
      }
    }
    elseif ($Formulae) {
      # Show only formulae
      Write-Host "📦 Formulae ($($formulaeList.Count) packages):" -ForegroundColor Yellow
      if ($formulaeList.Count -gt 0) {
        $formulaeList | Format-Table -AutoSize
      }
      else {
        Write-Host "   No formulae found" -ForegroundColor Gray
      }
    }
    elseif ($Casks) {
      # Show only casks
      Write-Host "🖥️ Casks ($($casksList.Count) applications):" -ForegroundColor Yellow
      if ($casksList.Count -gt 0) {
        $casksList | Format-Table -AutoSize
      }
      else {
        Write-Host "   No casks found" -ForegroundColor Gray
      }
    }

    # Return objects for pipeline
    if ($Formulae -or (!$Casks -and !$Formulae)) {
      return $formulaeList
    }
    if ($Casks) {
      return $casksList
    }
  }
  catch {
    Write-Error "An error occurred: $_"
  }
}

function Export-HomebrewPackages {
  [CmdletBinding()]
  param (
    [string]$OutputPath = "~/homebrew-packages.csv"
  )

  Write-Host "📋 Exporting Homebrew packages to $OutputPath..." -ForegroundColor Cyan
    
  $formulae = Get-HomebrewPackages -Formulae
  $casks = Get-HomebrewPackages -Casks
    
  # Add type column to distinguish formulae and casks
  $formulae | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name "Type" -Value "Formula" }
  $casks | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name "Type" -Value "Cask" }
    
  # Combine and export
  $allPackages = $formulae + $casks
  $allPackages | Export-Csv -Path $OutputPath -NoTypeInformation
    
  Write-Host "✅ Export completed to $OutputPath" -ForegroundColor Green
}

# Run with default parameters (show all)
Get-HomebrewPackages