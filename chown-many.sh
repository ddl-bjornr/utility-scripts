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
    count=$( find $folder -uid 0 | wc -l )
    echo "$count"
}

# Forking the count loop
count_uid0 &

# Function to change ownership of subfolders
change_ownership() {
    local subfolders=("$@")
    sleep 15
    chown -R "$new_owner:$new_group" "${subfolders[@]}"
}

# Iterate through each subfolder in the folder
subfolders=()
while IFS= read -r -d '' subfolder; do
    # Increment the count
    ((count++))

    # Add subfolder to the array
    subfolders+=("$subfolder")

    # If count reaches 5000, reset count and execute chown operation
    if [ $((count % 5000)) -eq 0 ]; then
        # Sort subfolders by length
        sorted_subfolders=($(printf "%s\n" "${subfolders[@]}" | awk '{print length, $0}' | sort -rn | cut -d" " -f2-))
        change_ownership "${sorted_subfolders[@]}"
        unset subfolders
    fi
done < <(find "$folder" -type d -print0)

# Change ownership of any remaining subfolders
if [ ${#subfolders[@]} -gt 0 ]; then
    # Sort subfolders by length
    sorted_subfolders=($(printf "%s\n" "${subfolders[@]}" | awk '{print length, $0}' | sort -rn | cut -d" " -f2-))
    change_ownership "${sorted_subfolders[@]}"
fi

# Wait for the count process to finish and get the final count
count=$(count_uid0)
echo "Files with UID 0: $count"
