#!/bin/bash

# Check if we're in a Git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "[ERROR] Not in a Git repository" >&2
    exit 1
fi

# Get files changed in the most recent commit
files=$(git diff-tree --no-commit-id --name-only -r HEAD)
if [ -z "$files" ]; then
    echo "[WARN] No files changed in the last commit"
    exit 0
fi

# Define pandoc arguments
pandoc_args=$(cat <<EOF
-f gfm
-t pdf
--pdf-engine=xelatex
-V mainfont='Noto Sans CJK SC'
-V geometry:margin=1in
--toc

EOF
)

# Flag to track if we found changes outside 'pdf/'
found_external_change=false

# Check for changes outside 'pdf/' directory
while IFS= read -r file; do
    if [[ "$file" != "pdf/"* ]]; then
        # Found a change outside 'pdf/' directory
        found_external_change=true
        
        # Check if it's a Markdown file
        if [[ "$file" == *.md ]]; then
            echo "[WARN] Compiling $file with pandoc..."
            
            # Create output path: same relative path but under pdf/ directory
            output_file="pdf/${file%.md}.pdf"
            
            # Create output directory if needed
            mkdir -p "$(dirname "$output_file")"
            
            # Compile with pandoc
            pandoc --default './scripts/pandoc-opts.yml'
        fi
    fi
done <<< "$files"

# Exit with appropriate status
if [ "$found_external_change" = true ]; then
    echo "Completed processing external changes"
    exit 0
else
    echo "All changes are confined to 'pdf/' directory"
    exit 0
fi