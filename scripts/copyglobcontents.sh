#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <glob_pattern>"
    exit 1
fi

# Get the glob pattern from the argument
pattern=$1

# Create a temporary file to store the result
tempfile=$(mktemp)

# Find all files matching the pattern and concatenate their contents
for file in $pattern; do
    if [ -f "$file" ]; then
        echo "# Start ./$file" >> "$tempfile"
        cat "$file" >> "$tempfile"
        echo -e "\n# End ./$file\n" >> "$tempfile"
    fi
done

# Copy the result to the clipboard using pbcopy
cat "$tempfile" | pbcopy

# Clean up the temporary file
rm "$tempfile"

echo "Contents copied to clipboard"
