#!/bin/bash

# Script to check if folder names in the submissions folder also exist in the marked folder,
# and delete those folders (and their contents) from the submissions folder if they do.

# Name of folder could be different, idea used to check between student submissions.


usage() {
    echo "Usage: $0 [options] <submissions_folder> <marked_submissions_folder>"
    echo "Options:"
    echo "  -c, --check-location     Check if the provided paths are in the same location as the script"
    echo "  -n, --dry-run            Show what would be deleted without actually deleting"
    echo "  -r, --recursive          Recursively check subdirectories"
    echo "  -h, --help               Display this help message"
    exit 1
}

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_LOCATION=false
DRY_RUN=false
RECURSIVE=false

# Parse options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c|--check-location) CHECK_LOCATION=true; shift ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
        -r|--recursive) RECURSIVE=true; shift ;;
        -h|--help) usage ;;
        --) shift; break ;;
        -*) echo "Unknown option: $1"; usage ;;
        *) break ;;
    esac
done

# Check if correct number of arguments is provided
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

# If not a dry run, ask for confirmation before proceeding
if [ "$DRY_RUN" = false ]; then
    echo "WARNING: This will delete entire folders and their contents from the submissions folder."
    read -p "Do you want to proceed with deleting duplicate folders? (y/n) " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "Operation cancelled."
        exit 0
    fi
fi

# Counter for deleted folders
DELETED_COUNT=0

# Process folders
echo "Checking for duplicate folder names..."

if [ "$RECURSIVE" = true ]; then
    # Using find for recursive search - find all directories in the submissions folder
    while IFS= read -r -d '' submission_dir; do
        # Skip the base directory itself
        if [ "$submission_dir" = "$SUBMISSIONS_FOLDER" ]; then
            continue
        fi
        
        # Get relative path from submissions folder
        rel_path=${submission_dir#$SUBMISSIONS_FOLDER/}
        # Get the same path in marked folder
        marked_dir="$MARKED_FOLDER/$rel_path"
        
        if [ -d "$marked_dir" ]; then
            echo "Found duplicate folder: $rel_path"
            if [ "$DRY_RUN" = false ]; then
                rm -rf "$submission_dir"
                DELETED_COUNT=$((DELETED_COUNT + 1))
                echo "  Deleted: $submission_dir"
            else
                echo "  Would delete folder and all contents: $submission_dir"
                DELETED_COUNT=$((DELETED_COUNT + 1))
            fi
        fi
    done < <(find "$SUBMISSIONS_FOLDER" -type d -print0)
else
    # Non-recursive, just check directories in the top level
    for submission_dir in "$SUBMISSIONS_FOLDER"/*/; do
        if [ -d "$submission_dir" ]; then
            # Get the folder name
            dirname=$(basename "$submission_dir")
            if [ -d "$MARKED_FOLDER/$dirname" ]; then
                echo "Found duplicate folder: $dirname"
                if [ "$DRY_RUN" = false ]; then
                    rm -rf "$submission_dir"
                    DELETED_COUNT=$((DELETED_COUNT + 1))
                    echo "  Deleted: $submission_dir"
                else
                    echo "  Would delete folder and all contents: $submission_dir"
                    DELETED_COUNT=$((DELETED_COUNT + 1))
                fi
            fi
        fi
    done
fi

if [ "$DRY_RUN" = true ]; then
    echo "Dry run completed. $DELETED_COUNT folders would be deleted from submissions folder."
else
    echo "Process completed. $DELETED_COUNT folders were deleted from submissions folder."
fi