#!/bin/bash

append=0

# Parse options
while getopts "a" opt; do
    case ${opt} in
        a )
            append=1
            ;;
        \? )
            echo "Usage: cmd [-a] <file_path>"
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# Check if a file path is provided
if [ $# -eq 0 ]; then
    echo "Please provide a file path as an argument."
    exit 1
fi

# Get the absolute path of the file
file_path=$(cd "$(dirname "$1")"; pwd -P)/$(basename "$1")

# Check if the file exists
if [ ! -f "$file_path" ]; then
    echo "File not found: $file_path"
    exit 1
fi

# Get the relative path of the file using awk
relative_path=$(echo "$file_path" | awk -v pwd="$(pwd)" '{
    sub(pwd "/?", "", $0); 
    print
}')

# Combine "File: ", the relative path, and file contents wrapped in Markdown code block
output=$(echo -e "File: $relative_path\n\n\`\`\`\n$(cat "$file_path")\n\`\`\`")

if [ $append -eq 1 ]; then
    # Get the current clipboard content and append the new output to it
    current_clipboard=$(pbpaste)
    output=$(echo -e "$current_clipboard\n\n$output")
fi

# Copy the output to clipboard using pbcopy
echo "$output" | pbcopy

echo "File contents with relative path copied to clipboard."
