#!/bin/bash
# 
# This script helps split files (CSV) into smaller chunks
#

# $file_path = "/Tier1/Historical_data.csv"

# Input Variables / Defaults
file_path="/Backups/Resources/Software/other/isolation/test.iso"
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

  return 0
}

getting_started_msg() {
  echo "Starting file processing..."
  echo "File path: $file_path"
  echo "Chunk size: $chunk_size lines"
  echo "Log level: $LOG_LEVEL"
}

process_file() {
  
  split -l $chunk_size $file_path part_

  for f in part_*; do
    # Check if the file is empty
    if ! validate_file "$f"; then
      exit 1
    fi
    echo "Processing $f"
    # Add your processing command here
    # For example, you can use psql to import the CSV into a database
    # psql -U postgres -d hist-trade-1 -c "\COPY option_quotes FROM '$PWD/$f' CSV HEADER"
    # Todo: Remove file (safely)
  done
}


process_args "$@"
if ! validate_file "$file_path" ; then exit 1; fi
getting_started_msg
process_file