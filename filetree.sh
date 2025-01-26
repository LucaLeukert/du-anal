#!/bin/bash

# Disk Usage Analysis Tool
# Author: Your Name
# Date: YYYY-MM-DD

# Default parameters
PATH_TO_ANALYZE=$(pwd)
DEPTH=0
MIN_SIZE_MB=20
PRINT_FILES=false

# Function to format size in human-readable format
format_size() {
    local size_bytes=$1
    if (( size_bytes < 1024 * 1024 * 200 )); then
        echo "$(bc <<< "scale=2; $size_bytes / 1024 / 1024") MB"
    else
        echo "$(bc <<< "scale=2; $size_bytes / 1024 / 1024 / 1024") GB"
    fi
}

# Function to get color based on size
get_color_based_on_size() {
    local size_bytes=$1
    local size_gb=$(bc <<< "scale=2; $size_bytes / 1024 / 1024 / 1024")
    if (( $(echo "$size_gb < 1" | bc -l) )); then
        echo -e "\033[32m" # Green
    elif (( $(echo "$size_gb >= 1 && $size_gb < 5" | bc -l) )); then
        echo -e "\033[33m" # Yellow
    elif (( $(echo "$size_gb >= 5 && $size_gb < 10" | bc -l) )); then
        echo -e "\033[35m" # Magenta
    else
        echo -e "\033[31m" # Red
    fi
}

# Function to calculate and print folder sizes
calculate_and_print_folder_sizes() {
    local path=$1
    local current_depth=$2

    # Calculate folder size
    local folder_size=$(du -sb "$path" 2>/dev/null | awk '{print $1}')
    if [[ -z $folder_size ]]; then
        folder_size=0
    fi

    # Print folder if it meets the size criteria
    if (( folder_size >= MIN_SIZE_MB * 1024 * 1024 )); then
        local indent=$(printf '│   %.0s' $(seq 1 $((current_depth - 1))))
        local folder_name=$(basename "$path")
        local folder_color=$(get_color_based_on_size "$folder_size")
        local formatted_size=$(format_size "$folder_size")

        echo -e "${indent}├── ${folder_color}${folder_name}\033[0m (${formatted_size})"
    fi

    # If PRINT_FILES is enabled, print file sizes
    if $PRINT_FILES; then
        find "$path" -maxdepth 1 -type f -size +"$((MIN_SIZE_MB * 1024 * 1024))c" 2>/dev/null | while read -r file; do
            local file_size=$(stat -c%s "$file")
            local file_name=$(basename "$file")
            local indent=$(printf '│   %.0s' $(seq 1 $current_depth))
            local formatted_size=$(format_size "$file_size")

            echo -e "${indent}├── \033[37m${file_name}\033[0m (${formatted_size})"
        done
    fi

    # Process subfolders if depth allows
    if (( DEPTH == 0 || current_depth < DEPTH )); then
        find "$path" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while read -r subfolder; do
            calculate_and_print_folder_sizes "$subfolder" $((current_depth + 1))
        done
    fi
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -Path)
            PATH_TO_ANALYZE="$2"
            shift 2
            ;;
        -Depth)
            DEPTH="$2"
            shift 2
            ;;
        -MinSize)
            MIN_SIZE_MB="$2"
            shift 2
            ;;
        -PrintFiles)
            PRINT_FILES=true
            shift
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
    esac
done

# Start time
start_time=$(date +%s)

# Header
echo -e "\033[36m"
cat << "EOF"
___  _  _    ____ _  _ ____ _    
|  \ |  | __ |__| |\ | |__| |    
|__/ |__|    |  | | \| |  | |___ 
EOF
echo -e "\033[0m"
echo "Analyzing Path: $PATH_TO_ANALYZE"
echo "Minimum Size Threshold: $MIN_SIZE_MB MB"
echo ""

# Perform analysis
calculate_and_print_folder_sizes "$PATH_TO_ANALYZE" 1

# End time
end_time=$(date +%s)
execution_time=$((end_time - start_time))

# Summary
echo ""
echo "=========================================="
echo -e "\033[32mAnalysis Complete!\033[0m"
echo "Execution Time: ${execution_time} seconds"
echo "=========================================="
