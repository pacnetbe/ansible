#!/bin/bash

# >> there are still some work to be done
# >> check comment lines

# SOURCE_DIR="/data/compose/1/storage/recordings"
# DEST_DIR="/mnt/frigate_archives"
# LOG_DIR="/data/compose/1/storage/log"
# LOG_FILE="$LOG_DIR/frigate-archive.log"
SIZE_LIMIT_GB=500
FREE_SPACE_THRESHOLD=10  # in percent
NBR_DAYS=15
STEP_BY_STEP=false
DRY_RUN=false
COMPRESS=false
REMOTE_COPY=""
DOCKER_CONTAINER="frigate"

# Parse arguments

while getopts "d:ncvl:ru:h:p:s" opt; do
  case ${opt} in
    d) NBR_DAYS="$OPTARG" ;;
    n) DRY_RUN=true ;;
	c) COMPRESS=true
    v) LOG_LEVEL="DEBUG" ;;
    l) LOG_FILE="$OPTARG" ;;
    r) REMOTE_COPY=true ;;
    u) REMOTE_USER="$OPTARG" ;;
    h) REMOTE_HOST="$OPTARG" ;;
    p) REMOTE_PATH="$OPTARG" ;;
	s) STEP_BY_STEP=true ;;
    *) echo "Usage: $0 [-d days] [-n] [-v] [-l log_file] [-r] [-u remote_user] [-h remote_host] [-p remote_path]"
       exit 1 ;;
  esac
done


##version with long arguments
# while [[ $# -gt 0 ]]; do
  # case "$1" in
    # -d|--days)
      # NBR_DAYS="$2"
      # shift 2
      # ;;
    # --dry-run)
      # DRY_RUN=true
      # shift
      # ;;
    # --compress)
      # COMPRESS=true
      # shift
      # ;;
    # --remote-copy)
      # REMOTE_COPY="$2"
      # shift 2
      # ;;
    # --step)
      # STEP_BY_STEP=true
      # shift
      # ;;
    # *)
      # echo "Unknown option: $1"
      # exit 1
      # ;;
  # esac
# done


# Determine source directory via docker inspect
STORAGE_MOUNT=$(docker inspect "$FRIGATE_CONTAINER" \
  --format '{{ range .Mounts }}{{ if eq .Destination "/media/frigate" }}{{ .Source }}{{ end }}{{ end }}')

if [ -z "$STORAGE_MOUNT" ]; then
  echo "Error: Could not determine storage mount from container $FRIGATE_CONTAINER"
  exit 1
fi

### >> check if "${STORAGE_MOUNT}/recordings" is the correct path
SOURCE_DIR="${STORAGE_MOUNT}/recordings"
DEST_DIR="/mnt/frigate_archives"
LOG_DIR="${STORAGE_MOUNT}/log"
LOG_FILE="${LOG_FILE:-$LOG_DIR/frigate-archive.log}"
# the log could be copied to DEST_DIR at the end of the script

# Ensure necessary directories
mkdir -p "$DEST_DIR" "$LOG_DIR"

function log() {
  echo "[$(date)] $*" >> "$LOG_FILE"
  echo "$*"
}

function step() {
  local message="$1"  # Store the first argument as message
  if [ "$STEP_BY_STEP" = true ]; then
    echo "$message" # print message
	echo # insert a cr
	read -n 1 -s -r -p "Press any key to continue..." && echo
  fi
}

# Safety checks
if ! docker inspect "$DOCKER_CONTAINER" &>/dev/null; then
  log "Container $DOCKER_CONTAINER not found."
  exit 1
fi

DISK_INFO=$(df -P "$SOURCE_DIR" | awk 'NR==2')
USED_PERCENT=$(echo "$DISK_INFO" | awk '{print $5}' | tr -d '%')
AVAIL_PERCENT=$((100 - USED_PERCENT))
DIR_SIZE=$(du -sBG "$SOURCE_DIR" | cut -f1 | tr -d 'G')

log "Starting archival check. Directory size: ${DIR_SIZE}G, Disk used: ${USED_PERCENT}%"

if [ "$DIR_SIZE" -gt "$SIZE_LIMIT_GB" ] || [ "$AVAIL_PERCENT" -lt "$FREE_SPACE_THRESHOLD" ]; then
  log "Archiving triggered (limit exceeded or low disk space). Moving files older than $NBR_DAYS days."
else
  log "Conditions not met. Archival skipped."
  exit 0
fi

find "$SOURCE_DIR" -type f -mtime +"$NBR_DAYS" | while read -r file; do
  rel_path="${file#$SOURCE_DIR/}"
  dest_path="$DEST_DIR/$rel_path"
  mkdir -p "$(dirname "$dest_path")"
  log "Moving: $file → $dest_path"
  step
  if [ "$DRY_RUN" = false ]; then
    mv "$file" "$dest_path" #add a log or is it auto logged?
  else
	echo "[DRY RUN] Would move: $file -> $dest_path" >> "$LOG_FILE"
  fi
done >> "$LOG_FILE" 2>&1 

# Clean up empty dirs
find "$SOURCE_DIR" -type d -empty -delete  >> "$LOG_FILE" 2>&1

# Optional: Compress
## > add dry-run
if [ "$COMPRESS" = true ]; then
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  ARCHIVE_NAME="/tmp/frigate_archive_$TIMESTAMP.tar.gz"
  log "Compressing archive to $ARCHIVE_NAME"
  step
  tar -czf "$ARCHIVE_NAME" -C "$DEST_DIR" .
fi

# Optional: Remote copy
## add dry-run test
## I guess I need some rsync credentials
if [ -n "$REMOTE_COPY" ]; then
  log "Copying to remote: $REMOTE_COPY"
  step
  if [ "$DRY_RUN" = false ]; then
    if [ -n "$REMOTE_DEST" ] && [ -n "$REMOTE_USER" ] && [ -n "$REMOTE_HOST" ] && [ -n "$REMOTE_PATH" ]; then
      echo "[$(date)] Copying archive to $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH" >> "$LOG_FILE"
      rsync -avz --remove-source-files "$DEST_DIR/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH" >> "$LOG_FILE" 2>&1
    fi
  else
    echo "[$(date)] [DRY RUN] would remote copy file." >> "$LOG_FILE"
  fi
fi
