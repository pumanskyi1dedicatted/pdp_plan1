#!/bin/bash
set -euo pipefail
shopt -s nullglob

DAYS_OLD=30
DIR_NAME="logs_$(hostname -s)_$(date +%Y-%m-%d_%H-%M-%S).tar.gz"
archive_dir="/var/backups/logs"
mkdir -p "$archive_dir"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

files=(/var/log/nginx/*.log)
if [ ${#files[@]} -eq 0 ];
then
    echo "There are no nginx logs to archive"
else
    cp "${files[@]}" "$tmp_dir/"
fi

journalctl --since "24 hours ago" --no-pager -o short-iso > "$tmp_dir/journal.log"
tar -czf "$archive_dir/$DIR_NAME" -C "$tmp_dir" .
find "$archive_dir" -type f -name "*.tar.gz" -mtime +$DAYS_OLD -delete

echo "Archive created: $archive_dir/$DIR_NAME"
