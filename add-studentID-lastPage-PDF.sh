#!/bin/bash

# Script to add a student ID page to the end of each PDF in student folders
# Requires: pdftk, ImageMagick (for convert command)
# Usage: ./add_student_id_page.sh [path_to_directory]

# Expects that studentID is the name of the folder its contained in. Downloaded from Moodle
# Folder has probably already been renamed to remove other contents, should just contain student_name
# Helpful for searching for a specific student in a large number of submissions - or with multiple files/versions.

# Set the A1 directory path (default to "A1" in current directory if not specified)
A1_DIR="${1:-./A1}"
TEMP_DIR="./temp_pdf_processing"

# Check if required tools are installed
if ! command -v pdftk &> /dev/null; then
    echo "Error: pdftk is not installed. Please install it first."
    echo "On macOS, you can use: brew install pdftk-java"
    exit 1
fi

if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is not installed. Please install it first."
    echo "On macOS, you can use: brew install imagemagick"
    exit 1
fi

# Create temp directory
mkdir -p "$TEMP_DIR"

echo "Processing student PDFs in ${A1_DIR}..."
processed_count=0
error_count=0

# Loop through each student directory in A1
for student_dir in "$A1_DIR"/*; do
    # Make sure it's a directory
    if [ -d "$student_dir" ]; then
        # Get the student ID from the directory name
        student_id=$(basename "$student_dir")
        echo "Processing student: $student_id"
        
        # Find PDF file in the student directory
        pdf_file=$(find "$student_dir" -maxdepth 1 -name "*.pdf" | head -n 1)
        
        if [ -z "$pdf_file" ]; then
            echo "  No PDF found for student $student_id"
            error_count=$((error_count + 1))
            continue
        fi
        
        # Create a page with student ID
        id_page="$TEMP_DIR/${student_id}_id_page.pdf"
        convert -size 612x792 -background white -fill black -pointsize 36 \
                -gravity center -font Helvetica \
                label:"Student ID: $student_id" \
                "$id_page"
        
        # Create the new PDF with the ID page appended
        output_pdf="$TEMP_DIR/${student_id}_with_id.pdf"
        if pdftk "$pdf_file" "$id_page" cat output "$output_pdf"; then
            # Backup the original PDF
            cp "$pdf_file" "${pdf_file}.backup"
            
            # Replace the original PDF with the new one
            mv "$output_pdf" "$pdf_file"
            echo "  ✓ Successfully added ID page to $pdf_file"
            processed_count=$((processed_count + 1))
        else
            echo "  ✗ Error processing PDF for student $student_id"
            error_count=$((error_count + 1))
        fi
    fi
done

# Cleanup
rm -rf "$TEMP_DIR"

echo "Processing complete."
echo "Successfully processed: $processed_count PDFs"
if [ $error_count -gt 0 ]; then
    echo "Errors encountered: $error_count"
fi