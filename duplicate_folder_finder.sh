#!/bin/bash

# Script to find duplicate folder names between two directories
# and export the list to a text file

usage() {
    echo "Usage: $0 [options] <submissions_folder> <marked_submissions_folder>"
    echo "Options:"
    echo "  -o, --output FILE        Specify output file for duplicate list (default: duplicates.txt)"
    echo "  -c, --check-location     Check if the provided paths are in the same location as the script"
    echo "  -r, --recursive          Recursively check subdirectories"
    echo "  -h, --help               Display this help message"
    exit 1
}

# Get the directory of current location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_LOCATION=false
RECURSIVE=false
OUTPUT_FILE="duplicates.txt"

# Parse options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -o|--output) 
            OUTPUT_FILE="$2"
            shift 2 
            ;;
        -c|--check-location) 
            CHECK_LOCATION=true
            shift 
            ;;
        -r|--recursive) 
            RECURSIVE=true
            shift 
            ;;
        -h|--help) 
            usage 
            ;;
        --) 
            shift
            break 
            ;;
        -*) 
            echo "Unknown option: $1"
            usage 
            ;;
        *) 
            break 
            ;;
    esac
done

# Check correct number of arguments
if [ "$#" -ne 2 ]; then
    usage
fi

SUBMISSIONS_FOLDER="$1"
MARKED_FOLDER="$2"

# Check if directories exist
if [ ! -d "$SUBMISSIONS_FOLDER" ]; then
    echo "Error: Submissions folder '$SUBMISSIONS_FOLDER' does not exist."
    exit 1
fi

if [ ! -d "$MARKED_FOLDER" ]; then
    echo "Error: Marked submissions folder '$MARKED_FOLDER' does not exist."
    exit 1
fi

# Check if the folders are in the same location as the script
if [ "$CHECK_LOCATION" = true ]; then
    # Convert to absolute paths
    SUBMISSIONS_ABS="$(cd "$SUBMISSIONS_FOLDER" && pwd)"
    MARKED_ABS="$(cd "$MARKED_FOLDER" && pwd)"
    
    echo "Script location: $SCRIPT_DIR"
    echo "Submissions folder absolute path: $SUBMISSIONS_ABS"
    echo "Marked folder absolute path: $MARKED_ABS"
    
    if [[ "$SUBMISSIONS_ABS" == "$SCRIPT_DIR"* ]]; then
        echo "Submissions folder is in the same location as the script or in a subdirectory."
    else
        echo "Submissions folder is NOT in the same location as the script."
    fi

    if [[ "$MARKED_ABS" == "$SCRIPT_DIR"* ]]; then
        echo "Marked submissions folder is in the same location as the script or in a subdirectory."
    else
        echo "Marked submissions folder is NOT in the same location as the script."
    fi
fi

# Count duplicates
DUPLICATE_COUNT=0

# Clear the output file if it exists
echo "# Duplicate folders found between:" > "$OUTPUT_FILE"
echo "# Submissions: $SUBMISSIONS_FOLDER" >> "$OUTPUT_FILE"
echo "# Marked: $MARKED_FOLDER" >> "$OUTPUT_FILE"
echo "# Generated on: $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "Checking for duplicate folder names..."

if [ "$RECURSIVE" = true ]; then
    echo "# Checking recursively through all subdirectories" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Create a temp file to store all folders from submissions
    TEMP_SUBMISSIONS=$(mktemp)
    # Create a temp file to store all folders from marked
    TEMP_MARKED=$(mktemp)
    
    # List all subdirectories in submissions (relative paths)
    find "$SUBMISSIONS_FOLDER" -type d | sed "s|^$SUBMISSIONS_FOLDER/||" | grep -v "^$" > "$TEMP_SUBMISSIONS"
    
    # List all subdirectories in marked (relative paths)
    find "$MARKED_FOLDER" -type d | sed "s|^$MARKED_FOLDER/||" | grep -v "^$" > "$TEMP_MARKED"
    
    # Find duplicates (folders that exist in both places)
    echo "## Duplicate folders (full paths):" >> "$OUTPUT_FILE"
    while IFS= read -r rel_path; do
        if [ -d "$MARKED_FOLDER/$rel_path" ]; then
            echo "Found duplicate folder: $rel_path"
            echo "$SUBMISSIONS_FOLDER/$rel_path" >> "$OUTPUT_FILE"
            DUPLICATE_COUNT=$((DUPLICATE_COUNT + 1))
        fi
    done < "$TEMP_SUBMISSIONS"
    
    # Clean up temp files
    rm "$TEMP_SUBMISSIONS" "$TEMP_MARKED"
else
    echo "# Checking only top-level directories" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "## Duplicate folders (full paths):" >> "$OUTPUT_FILE"
    
    # Non-recursive, just check directories in the top level
    for submission_dir in "$SUBMISSIONS_FOLDER"/*/; do
        if [ -d "$submission_dir" ]; then
            # Get the folder name
            dirname=$(basename "$submission_dir")
            if [ -d "$MARKED_FOLDER/$dirname" ]; then
                echo "Found duplicate folder: $dirname"
                echo "$submission_dir" >> "$OUTPUT_FILE"
                DUPLICATE_COUNT=$((DUPLICATE_COUNT + 1))
            fi
        fi
    done
fi

# Add summary to the output file
echo "" >> "$OUTPUT_FILE"
echo "## Summary" >> "$OUTPUT_FILE"
echo "Total duplicate folders found: $DUPLICATE_COUNT" >> "$OUTPUT_FILE"

echo "Process completed. Found $DUPLICATE_COUNT duplicate folders."
echo "Results have been saved to: $OUTPUT_FILE"