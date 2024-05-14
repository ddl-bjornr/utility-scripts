#!/bin/bash

# Check if user and group parameters are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <folder_path> <new_owner> <new_group>"
    exit 1
fi

# Set the folder path
folder="$1"
new_owner="$2"
new_group="$3"

# Counter for files with uid 0
count=0

# Function to count files with uid 0
count_uid0() {
    local file
    local count=0
    for file in "$folder"/*; do
        if [ $(stat -c '%u' "$file") -eq 0 ]; then
            ((count++))
        fi
    done
    echo "$count"
}

# Forking the count loop
count_uid0 &

# Function to change ownership of files
change_ownership() {
    local files=("$@")
    chown "$new_owner:$new_group" "${files[@]}"
}

# Iterate through each file in the folder
while IFS= read -r -d '' file; do
    # Increment the count
    ((count++))

    # Change ownership of the file
    chown "$new_owner:$new_group" "$file"
    echo "Changed ownership of $file"

    # If count reaches 5000, reset count and execute chown operation
    if [ $((count % 5000)) -eq 0 ]; then
        change_ownership "${files[@]}"
        unset files
    else
        files+=("$file")
    fi
done < <(find "$folder" -type f -print0)

# Change ownership of any remaining files
if [ ${#files[@]} -gt 0 ]; then
    change_ownership "${files[@]}"
fi

# Wait for the count process to finish and get the final count
count=$(count_uid0)
echo "Files with UID 0: $count"
