# !/bin/bash
# 
# This script helps split files (CSV) into smaller chunks
# Change test 3 (from STORAGE01)

# $file_path = "/Tier1/Historical_data.csv"
# Testing with an ISO file I could find at the time... (Temporary)
$file_path = "/Backups/Resources/Software/other/isolation/test.iso"

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

split -l $chunk_size $file_path part_
for f in part_*; do
#   psql -U postgres -d hist-trade-1 \
#     -c "\COPY option_quotes FROM '$PWD/$f' CSV HEADER"
  echo "Processing $f"
  # Add your processing command here
  # For example, you can use psql to import the CSV into a database
  # psql -U postgres -d hist-trade-1 -c "\COPY option_quotes FROM '$PWD/$f' CSV HEADER"
  rm $f
done