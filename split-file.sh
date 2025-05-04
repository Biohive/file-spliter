#!/bin/bash
# 
# This script helps split files (CSV) into smaller chunks
#
# Test file location: "/Tier1/test/Historical_data.csv"

# Input Variables / Defaults
file_path=""
chunk_size=5000000
dev_mode=false
LOG_LEVEL="INFO"

process_args() {
    for arg in "$@"; do
        case $arg in
            -h|--help) usage ;;
            --log-level=*) LOG_LEVEL="${arg#*=}" ;;
            --dev) dev_mode=true ;;
            --file-path=*) file_path="${arg#*=}" ;;
            --chunk-size=*) chunk_size="${arg#*=}" ;;
            *)
            usage "$arg" ;;
        esac
    done
}

#region Usage Function
usage() {
  if [ -n "${1-}" ]; then
    echo "${RED}Error:${NORMAL} Unknown or invalid argument: $1"
  fi
  echo
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Description:
    This 'split-file.sh' helps split large csv files into smaller chunks for easier processing.

General options:
    -h, --help                    Display this help message

File Split options:
    --file-path=FILE_PATH         Path to the file to be split (required)
    --chunk-size=CHUNK_SIZE       Size of each chunk in lines (default: 5000000)

Logging options:
    --log-level=LEVEL             Set the log level (DEBUG, INFO, WARN, ERROR)

Development options:
    --dev                         Enable development mode

EOF
  exit 1
}
#endregion

validate_file() {
  local file_path_to_validate="$1"

  if [ -z "$file_path_to_validate" ]; then
    echo "File path is required."
    return 1
  fi
  if [ ! -f "$file_path_to_validate" ]; then
    echo "File $file_path_to_validate does not exist."
    return 1
  fi

  if [ ! -r "$file_path_to_validate" ]; then
    echo "File $file_path_to_validate is not readable."
    return 1
  fi

  if [ ! -s "$file_path_to_validate" ]; then
    echo "File $file_path_to_validate is empty."
    return 1
  fi

  return "0"
}

# Improved function to get the file size with better precision
get_file_size() {
  local file_path_to_check="$1"
  if [ -f "$file_path_to_check" ]; then
    file_size_bytes=$(stat --format="%s" "$file_path_to_check")
    
    # Use awk for more precise calculation and formatting
    file_size_gb=$(awk "BEGIN {printf \"%.2f\", $file_size_bytes / (1024 * 1024 * 1024)}")
    
    echo "$file_size_gb"
  else
    echo "0.00"
  fi
}

# More reliable function to get the number of parts based on chunk size
get_parts_count() {
  local input_file="$1"
  local chunk_size="$2"
  
  # Use wc -l with explicit file path to ensure proper counting
  local total_lines=$(wc -l < "$input_file")
  
  # Use awk for more reliable division with large numbers
  local parts_count=$(awk "BEGIN {print int(($total_lines + $chunk_size - 1) / $chunk_size)}")
  
  # If something went wrong and we got 0 or no result, calculate a fallback
  if [ -z "$parts_count" ] || [ "$parts_count" -eq 0 ]; then
    # Get file size and estimate based on average line size (approx 100 bytes/line)
    local file_size_bytes=$(stat --format="%s" "$input_file")
    local estimated_lines=$(($file_size_bytes / 100))
    parts_count=$(($estimated_lines / $chunk_size + 1))
  fi
  
  echo "$parts_count"
}

# Function to display a message at the start
getting_started_msg() {
  echo "File path: $file_path"
  echo "File size: $(get_file_size "$file_path") Gigabytes"
  echo "Chunk size: $chunk_size lines"
  echo "Expected number of parts: $(get_parts_count "$file_path" "$chunk_size")"
  echo "Log level: $LOG_LEVEL"
  echo -e "\n" 
}

# Function to format seconds to HH:MM:SS
format_time() {
  local seconds=$1
  local hours=$(( seconds / 3600 ))
  local minutes=$(( (seconds % 3600) / 60 ))
  local secs=$(( seconds % 60 ))
  printf "%02d:%02d:%02d" $hours $minutes $secs
}

process_file() {
  local total_parts=$(get_parts_count "$file_path" "$chunk_size")
  local start_time=$(date +%s)
  local part_count=0
  
  # Extract directory from file_path
  local input_dir=$(dirname "$file_path")
  local filename=$(basename "$file_path")
  local output_prefix="${input_dir}/part_${filename%.*}_"
  
  echo "Starting file split process..."
  echo "Writing part files to: ${input_dir}"
  
  # Use the output_prefix with path for split command
  split -l $chunk_size "$file_path" "$output_prefix"
  
  for f in "${input_dir}"/part_*; do
    # Check if the file is empty
    if ! validate_file "$f"; then
      exit 1
    fi
    
    part_count=$((part_count + 1))
    local current_time=$(date +%s)
    local elapsed_time=$((current_time - start_time))
    
    # Calculate progress and estimates
    local percent_complete=$(( (part_count * 100) / total_parts ))
    
    # Only calculate average and ETA if we've completed at least one part
    if [ $part_count -gt 0 ]; then
      local avg_time_per_part=$(( elapsed_time / part_count ))
      local remaining_parts=$((total_parts - part_count))
      local est_remaining_time=$((avg_time_per_part * remaining_parts))
      local est_completion_formatted=$(format_time $est_remaining_time)
    else
      local est_completion_formatted="calculating..."
    fi
    
    echo "Processing $f (part $part_count of $total_parts)"
    echo "File size of part: $(get_file_size "$f") Gigabytes"
    echo "Progress: $percent_complete% complete"
    echo "Elapsed time: $(format_time $elapsed_time)"
    echo "Estimated time remaining: $est_completion_formatted"
    echo "----------------------------------------"
    
    # Add your processing command here
    # For example, you can use psql to import the CSV into a database
    # psql -U postgres -d hist-trade-1 -c "\COPY option_quotes FROM '$PWD/$f' CSV HEADER"
    # Todo: Remove file (safely)
  done
  
  local total_time=$(( $(date +%s) - start_time ))
  echo "Processing complete! Total time: $(format_time $total_time)"
}

process_args "$@"
if ! validate_file "$file_path" ; then exit 1; fi
getting_started_msg
process_file