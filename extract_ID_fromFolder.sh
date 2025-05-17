#!/bin/bash

# =================================================================
# extract_ID_fromFolder.sh
# 
# This script extracts student IDs from folder names that match
# the pattern: studentID-FIRSTNAME LASTNAME_XXXXXXX_assignsubmission_file
# and saves them to a text file (id_list.txt) with one ID per line.
#
# Usage:
#   ./extract_ID_fromFolder.sh [directory_path]
#
# Arguments:
#   directory_path (optional): Path to the directory containing the folders.
#                             If not provided, current directory is used.
#
# Examples:
#   ./extract_ID_fromFolder.sh              # Use current directory
#   ./extract_ID_fromFolder.sh ./submissions # Use ./submissions directory
#
# Output:
#   Creates or overwrites id_list.txt in the current directory
#   containing all extracted student IDs, one per line.
# =================================================================

# Function to display usage information
function show_usage {
    echo "Usage: $0 [directory_path]"
    echo ""
    echo "This script extracts student IDs from folder names matching the pattern:"
    echo "studentID-FIRSTNAME LASTNAME_XXXXXXX_assignsubmission_file"
    echo ""
    echo "Arguments:"
    echo "  directory_path (optional): Path to directory containing folders."
    echo "                            If not provided, current directory is used."
    echo ""
    echo "Output:"
    echo "  Creates or overwrites id_list.txt containing all extracted student IDs."
}

# Process command line arguments
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    show_usage
    exit 0
fi

# Set the directory to scan (default to current directory if not provided)
DIRECTORY="${1:-.}"

# Check if the directory exists
if [ ! -d "$DIRECTORY" ]; then
    echo "Error: Directory '$DIRECTORY' does not exist."
    echo ""
    show_usage
    exit 1
fi

echo "Scanning for student submission folders in: $DIRECTORY"

# Create or clear the output file
OUTPUT_FILE="id_list.txt"
> "$OUTPUT_FILE"

# Counter for found IDs
COUNT=0

# Find folders matching the pattern and extract student IDs
for folder in "$DIRECTORY"/*-*_*_assignsubmission_file; do
    # Skip if no matching files are found (when the pattern doesn't expand)
    [ -e "$folder" ] || continue
    
    # Check if the item is a directory
    if [ -d "$folder" ]; then
        # Extract just the studentID from the beginning of the folder name
        # This handles both the specific pattern and similar patterns
        base_folder=$(basename "$folder")
        studentID=$(echo "$base_folder" | sed -E 's/^([0-9]+)-.*$/\1/')
        
        # Validate that we got a numeric ID
        if [[ "$studentID" =~ ^[0-9]+$ ]]; then
            echo "$studentID" >> "$OUTPUT_FILE"
            ((COUNT++))
            echo "Found student ID: $studentID from folder: $base_folder"
        else
            echo "Warning: Could not extract valid student ID from folder: $base_folder"
        fi
    fi
done

# Also try an alternative pattern (in case folder names have slight variations)
for folder in "$DIRECTORY"/*-*_assignsubmission_file; do
    # Skip if no matching files are found
    [ -e "$folder" ] || continue
    
    # Skip folders we've already processed
    if [[ "$folder" == *-*_*_assignsubmission_file ]]; then
        continue
    fi
    
    # Check if the item is a directory
    if [ -d "$folder" ]; then
        # Extract just the studentID
        base_folder=$(basename "$folder")
        studentID=$(echo "$base_folder" | sed -E 's/^([0-9]+)-.*$/\1/')
        
        # Validate that we got a numeric ID
        if [[ "$studentID" =~ ^[0-9]+$ ]]; then
            # Check if this ID is already in our file
            if ! grep -q "^$studentID$" "$OUTPUT_FILE"; then
                echo "$studentID" >> "$OUTPUT_FILE"
                ((COUNT++))
                echo "Found student ID: $studentID from folder: $base_folder"
            fi
        else
            echo "Warning: Could not extract valid student ID from folder: $base_folder"
        fi
    fi
done

# Sort the IDs and remove any duplicates
if [ $COUNT -gt 0 ]; then
    sort -n "$OUTPUT_FILE" | uniq > "${OUTPUT_FILE}.temp"
    mv "${OUTPUT_FILE}.temp" "$OUTPUT_FILE"
    FINAL_COUNT=$(wc -l < "$OUTPUT_FILE")
    
    echo ""
    echo "Extraction complete!"
    echo "Found $COUNT student IDs (${FINAL_COUNT} unique)"
    echo "Student IDs have been saved to $OUTPUT_FILE"
else
    echo ""
    echo "No matching folders found in $DIRECTORY"
    echo "Please check that the folders follow the expected naming pattern:"
    echo "studentID-FIRSTNAME LASTNAME_XXXXXXX_assignsubmission_file"
    # Clean up empty output file
    rm "$OUTPUT_FILE"
fi