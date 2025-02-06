#!/bin/bash
source ../config/config.sh

# Function to perform a complete cleanup of cgroup v1 resources.
precleanup() {
    log "Performing complete cleanup of cgroup v1 resources..."

    # Get a list of mounted cgroup v1 controllers
    legacy_mounts=$(mount | grep '^cgroup ' | awk '{print $3}')

    for mount_point in $legacy_mounts; do
        log "Cleaning up legacy cgroup v1 mount: $mount_point"

        # Move all processes back to root cgroup
        if [ -f "$mount_point/tasks" ]; then
            while read -r pid; do
                if [ -d "/proc/$pid" ]; then
                    echo "$pid" > /sys/fs/cgroup/tasks 2>/dev/null || true
                fi
            done < "$mount_point/tasks"
        fi

        # Unmount the cgroup v1 controller
        if ! umount "$mount_point" 2>/dev/null; then
            if ! umount -l "$mount_point" 2>/dev/null; then
                log "Warning: Could not unmount $mount_point, may require manual intervention"
            fi
        fi
    done

    # Remove any leftover cgroup v1 directories
    find /sys/fs/cgroup/* -type d -not -name 'cgroup*' -exec rmdir {} \; 2>/dev/null || true

    log "Legacy cgroup v1 controllers have been fully cleaned up"
}
