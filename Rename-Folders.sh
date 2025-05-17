#!/bin/bash

# Submissions are downloaded from Moodle and unzipped into folders
# This script renames folders to just the student ID
# Usage: ./rename_folders.sh [--preview] [-h|--help]

# Script to extract and rename folders to just the studentID
# Works with various formats like:
# - studetnID - FIRSTNAME LASTNAME_XXXXXXX_assignsubmission_file -> studentID
# - studentID - Other formats

# Default settings
PREVIEW_MODE=false
SHOW_HELP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --preview)
            PREVIEW_MODE=true
            shift
            ;;
        -h|--help)
            SHOW_HELP=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Show help
if $SHOW_HELP; then
    echo "Rename Assignment Folders Script"
    echo "==============================="
    echo ""
    echo "Usage: ./rename_folders.sh [--preview] [-h|--help]"
    echo ""
    echo "Parameters:"
    echo "  --preview     : Only show what would be renamed without making changes"
    echo "  -h, --help    : Show this help message"
    echo ""
    echo "This script extracts the student ID from the beginning of folder names"
    echo "and renames folders to just that ID."
    echo ""
    echo "Examples of supported formats:"
    echo "  - 42511860-FIRSTNAME LASTNAME_XXXXXXX_assignsubmission_file"
    echo "  - 46349103 - FIRSTNAME LASTNAME_XXXXXXX_assignsubmission_file"
    echo "  - 47298111-Other formats"
    exit 0
fi

# Check directory
echo "This script will rename folders in the current directory."
echo "Current directory: $(pwd)"

if $PREVIEW_MODE; then
    echo "PREVIEW MODE: No folders will be renamed"
else
    echo "Press Enter to continue or Ctrl+C to cancel."
    read
fi

# Counter for matches
MATCH_COUNT=0

# First pass: Collect all the new names
echo "Analysing folders..."
RENAME_LIST=""

for folder in *; do
    # Skip if not a directory
    if [ ! -d "$folder" ]; then
        continue
    fi
    
    # Check if the folder starts with a numeric student ID
    # Pattern: Extract digits from the beginning until non-digit, hyphen or space
    if [[ $folder =~ ^([0-9]+)[-\ ].*$ ]]; then
        studentID="${BASH_REMATCH[1]}"
        
        # Verify we have a valid student ID (reasonable length)
        if [[ ${#studentID} -lt 5 || ${#studentID} -gt 10 ]]; then
            echo "Warning: Extracted ID '$studentID' from '$folder' seems invalid (unusual length), skipping..."
            continue
        fi
        
        # Add to our rename list
        RENAME_LIST="$RENAME_LIST\n$folder|$studentID"
        ((MATCH_COUNT++))
    fi
done

# No matches found
if [[ $MATCH_COUNT -eq 0 ]]; then
    echo "No folders matched the pattern for student IDs."
    echo "Looking for folders that start with numbers followed by a hyphen or space."
    
    # Show some example folder names if available
    example_count=0
    for folder in */; do
        folder=${folder%/}
        if [ -d "$folder" ]; then
            echo "  $folder"
            ((example_count++))
            if [[ $example_count -eq 3 ]]; then
                break
            fi
        fi
    done
    exit 0
fi

# Process the rename list to handle duplicates
echo -e "$RENAME_LIST" | sort | grep -v "^$" > /tmp/rename_list.txt

# Array for tracking used names
used_names=()

# Read the rename list and process duplicates
while IFS="|" read -r src_name dest_name; do
    # Skip empty lines
    if [[ -z "$src_name" ]]; then
        continue
    fi
    
    # Check if destination name already exists or is planned to be used
    name_exists=false
    base_name="$dest_name"
    counter=1
    
    for used in "${used_names[@]}"; do
        if [[ "$used" == "$dest_name" ]]; then
            name_exists=true
            break
        fi
    done
    
    # If name exists, add a suffix
    if $name_exists || [ -d "$dest_name" ]; then
        echo "Warning: Name '$dest_name' already used or exists, adding suffix for $src_name"
        while $name_exists || [ -d "$dest_name" ]; do
            dest_name="${base_name}_$counter"
            ((counter++))
            
            # Check if this new name is also used
            name_exists=false
            for used in "${used_names[@]}"; do
                if [[ "$used" == "$dest_name" ]]; then
                    name_exists=true
                    break
                fi
            done
        done
        echo "  -> Using '$dest_name' instead"
    fi
    
    # Add to used names
    used_names+=("$dest_name")
    
    echo "Renaming: $src_name -> $dest_name"
    
    # Rename the folder if not in preview mode
    if ! $PREVIEW_MODE; then
        mv "$src_name" "$dest_name" 2>/dev/null
        
        # Verify rename worked
        if [ -d "$dest_name" ]; then
            echo "  -> Successfully renamed"
        else
            echo "  -> Failed to rename"
        fi
    fi
done < /tmp/rename_list.txt

# Clean up
rm -f /tmp/rename_list.txt

# Report results
if $PREVIEW_MODE; then
    echo "Preview complete! $MATCH_COUNT folder(s) would be renamed."
    echo "Run without --preview to perform the rename operation."
else
    echo "Renaming complete! $MATCH_COUNT folder(s) renamed."
fi