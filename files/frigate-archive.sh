#!/bin/bash

# Default values
NBR_DAYS=15
DRY_RUN=false
LOG_LEVEL="INFO"
REMOTE_DEST=""
REMOTE_USER=""
REMOTE_HOST=""
REMOTE_PATH=""
FRIGATE_CONTAINER="frigate"

# Parse options
while getopts "d:n:vl:r:u:h:p:" opt; do
  case ${opt} in
    d) NBR_DAYS="$OPTARG" ;;
    n) DRY_RUN=true ;;
    v) LOG_LEVEL="DEBUG" ;;
    l) LOG_FILE="$OPTARG" ;;
    r) REMOTE_DEST=true ;;
    u) REMOTE_USER="$OPTARG" ;;
    h) REMOTE_HOST="$OPTARG" ;;
    p) REMOTE_PATH="$OPTARG" ;;
    *) echo "Usage: $0 [-d days] [-n] [-v] [-l log_file] [-r] [-u remote_user] [-h remote_host] [-p remote_path]"
       exit 1 ;;
  esac
done

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
FREE_SPACE_THRESHOLD=10

# Ensure necessary directories
mkdir -p "$DEST_DIR"
mkdir -p "$LOG_DIR"

# Get used disk space in %
USED_PERCENT=$(df -P "$SOURCE_DIR" | awk 'NR==2 {print $5}' | tr -d '%')
# Get total size of source directory
USED_GB=$(du -sBG "$SOURCE_DIR" | cut -f1 | tr -d 'G')

echo "[$(date)] Starting archival check. Directory size: ${USED_GB}G, Disk used: ${USED_PERCENT}%" >> "$LOG_FILE"

if [ "$USED_GB" -gt "$SIZE_LIMIT_GB" ] || [ "$USED_PERCENT" -gt $((100 - FREE_SPACE_THRESHOLD)) ]; then
  echo "[$(date)] Archiving triggered (limit exceeded or low disk space). Moving files older than $NBR_DAYS days." >> "$LOG_FILE"

  find "$SOURCE_DIR" -type f -mtime +$NBR_DAYS | while read -r file; do
    rel_path="${file#$SOURCE_DIR/}"
    dest_path="$DEST_DIR/$rel_path"
    mkdir -p "$(dirname "$dest_path")"
    
    if [ "$DRY_RUN" = true ]; then
      echo "[DRY RUN] Would move: $file -> $dest_path" >> "$LOG_FILE"
    else
      mv -v "$file" "$dest_path"
    fi
  done >> "$LOG_FILE" 2>&1

  # Clean up empty dirs
  find "$SOURCE_DIR" -type d -empty -delete >> "$LOG_FILE" 2>&1

  # Optional: copy to remote host
  if [ -n "$REMOTE_DEST" ] && [ -n "$REMOTE_USER" ] && [ -n "$REMOTE_HOST" ] && [ -n "$REMOTE_PATH" ]; then
    echo "[$(date)] Copying archive to $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH" >> "$LOG_FILE"
    rsync -avz --remove-source-files "$DEST_DIR/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH" >> "$LOG_FILE" 2>&1
  fi
else
  echo "[$(date)] No archival needed. Disk usage is within limits." >> "$LOG_FILE"
fi
