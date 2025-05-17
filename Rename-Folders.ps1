# PowerShell script to rename folders from:
# studentID-FIRSTNAME LASTNAME_XXXXXXX_assignsubmission_file
# to: studentID

# Checks right directory
Write-Host "This script will rename folders in the current directory."
Write-Host "Current directory: $(Get-Location)"
Write-Host "Press Enter to continue or Ctrl+C to cancel."
$null = Read-Host

# Get all folders matching the pattern
$folders = Get-ChildItem -Directory -Filter "*-*_*_assignsubmission_file"

foreach ($folder in $folders) {
    # Extract just the studentID from the beginning of the folder name
    $studentID = $folder.Name -replace "^(.*?)-.*_.*_assignsubmission_file.*$", '$1'
    
    Write-Host "Renaming: $($folder.Name) -> $studentID"
    
    # Rename the folder
    Rename-Item -Path $folder.FullName -NewName $studentID
}

Write-Host "Renaming complete!"
