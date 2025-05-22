#!/bin/bash
set -euo pipefail

########################################
# CONFIGURATION (via environment or defaults)
########################################

SRC_DIR="${SRC_DIR:-/mnt/frigate_archives}"
TMP_DIR="${TMP_DIR:-/tmp/frigate_archive_tmp}"
REMOTE_USER="${REMOTE_USER:-backupuser}"
REMOTE_HOST="${REMOTE_HOST:-homenas.lan}"
REMOTE_DIR="${REMOTE_DIR:-/mnt/data/frigatearchive}"
LOG_FILE="${LOG_FILE:-/var/log/frigate_archive_move.log}"
DRY_RUN="${DRY_RUN:-false}"
MAX_RETRIES="${MAX_RETRIES:-3}"
ALERT_CMD="${ALERT_CMD:-logger -t frigate-archive '[ERROR]'}"

SSH_TARGET="${REMOTE_USER}@${REMOTE_HOST}"

########################################
# FUNCTIONS
########################################

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

alert() {
    $ALERT_CMD "$*" || echo "ALERT FAILED: $*" >> "$LOG_FILE"
}

retry_cmd() {
    local n=0
    until [ "$n" -ge "$MAX_RETRIES" ]; do
        "$@" && return 0
        n=$((n+1))
        sleep 5
        log "Retrying ($n/$MAX_RETRIES)..."
    done
    return 1
}

transfer_to_nas() {
    local src="$1"
    if $DRY_RUN; then
        log "[DRY RUN] Would copy $src to ${SSH_TARGET}:${REMOTE_DIR}/"
        return 0
    fi

    if retry_cmd rsync -avz -e ssh "$src" "${SSH_TARGET}:${REMOTE_DIR}/"; then
        log "Transferred archive to NAS: $(basename "$src")"
        return 0
    else
        alert "Failed to transfer $src after $MAX_RETRIES attempts"
        return 1
    fi
}

########################################
# MAIN
########################################

mkdir -p "$TMP_DIR"
log "==== Starting archive move job ===="

# Find all day directories at level: year/month/day/hour
find "$SRC_DIR" -mindepth 4 -maxdepth 4 -type d -printf "%P\n" | while read -r relative_day_path; do
    full_day_path="$SRC_DIR/$relative_day_path"

    if [[ $(find "$full_day_path" -type f -mtime +30 | wc -l) -eq 0 ]]; then
        continue
    fi

    year=$(echo "$relative_day_path" | cut -d/ -f1)
    month=$(echo "$relative_day_path" | cut -d/ -f2)
    day=$(echo "$relative_day_path" | cut -d/ -f3)
    day_stamp="${year}-${month}-${day}"

    log "Processing $day_stamp..."
    day_dir="$TMP_DIR/$day_stamp"
    mkdir -p "$day_dir"

    find "$full_day_path" -mindepth 2 -maxdepth 2 -type d | while read -r hour_dir; do
        cam_name=$(basename "$(dirname "$hour_dir")")
        hour=$(basename "$hour_dir")
        cam_hour_dir="$day_dir/$cam_name/${hour}"
        mkdir -p "$cam_hour_dir"
        rsync -a "$hour_dir/" "$cam_hour_dir/"
    done

    tarball_name="frigate_${day_stamp}.tar.zst"
    tarball_path="$TMP_DIR/$tarball_name"

    if $DRY_RUN; then
        log "[DRY RUN] Would compress $day_stamp -> $tarball_name"
    else
        tar -I 'zstd -19' -cf "$tarball_path" -C "$day_dir" .
        log "Compressed $day_stamp -> $tarball_name"
    fi

    if transfer_to_nas "$tarball_path"; then
        rm -f "$tarball_path"
    else
        continue
    fi

    rm -rf "$day_dir"
    log "Cleaned up temp directory for $day_stamp"

    if ! $DRY_RUN; then
        log "Removing source directory: $full_day_path"
        rm -rf "$full_day_path"
    else
        log "[DRY RUN] Would remove $full_day_path"
    fi
done

log "==== Archive job finished ===="
