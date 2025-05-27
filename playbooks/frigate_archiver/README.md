# Frigate backup script and systemD files

Script .sh features
  This script will move recordings to a different attached drive based on either number of days to keep or min free space.
  There are options controlled by switches.
  There is an option to copy the files to a remote location

#Switches:
[-d days] [-n] [-v] [-l log_file] [-r] [-u remote_user] [-h remote_host] [-p remote_path]"
    -d = NBR_DAYS="$OPTARG" ;;
    -n = DRY_RUN=true ;;
    -v = LOG_LEVEL="DEBUG" ;;
    -l = LOG_FILE="$OPTARG" ;;
    -r = REMOTE_DEST=true ;;
    -u = REMOTE_USER="$OPTARG" ;;
    -h = REMOTE_HOST="$OPTARG" ;;
    -p = REMOTE_PATH="$OPTARG" ;;
    *) echo "Usage: $0 [-d days] [-n] [-v] [-l log_file] [-r] [-u remote_user] [-h remote_host] [-p remote_path]"
# Default values
* NBR_DAYS=15
* DRY_RUN=false
* LOG_LEVEL="INFO"
* REMOTE_DEST=""
* REMOTE_USER=""
* REMOTE_HOST=""
* REMOTE_PATH=""
* FRIGATE_CONTAINER="frigate"

# Determine source directory via docker inspect
STORAGE_MOUNT=$(docker inspect "$FRIGATE_CONTAINER" \
  --format '{{ range .Mounts }}{{ if eq .Destination "/media/frigate" }}{{ .Source }}{{ end }}{{ end }}')

if [ -z "$STORAGE_MOUNT" ]; then
  echo "Error: Could not determine storage mount from container $FRIGATE_CONTAINER"
  exit 1
fi

  SOURCE_DIR="${STORAGE_MOUNT}/recordings"
  DEST_DIR="/mnt/frigate_archives"
  LOG_DIR="${STORAGE_MOUNT}/log"
  LOG_FILE="${LOG_FILE:-$LOG_DIR/frigate-archive.log}"

SIZE_LIMIT_GB=500
FREE_SPACE_THRESHOLD=10 # 10% free
