#!/bin/bash

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

# Function to set up cgroup v2 with delegation to the current user.
setup_cgroup_v2() {
    log "Setting up cgroup v2 with delegation to $USER..."

    # Ensure cgroup v2 is mounted
    if ! mountpoint -q /sys/fs/cgroup; then
        mount -t cgroup2 none /sys/fs/cgroup || error_exit "Failed to mount cgroup v2"
    else
        if ! grep -qw cgroup2 /proc/mounts; then
            log "Remounting /sys/fs/cgroup as cgroup2"
            umount /sys/fs/cgroup
            mount -t cgroup2 none /sys/fs/cgroup || error_exit "Failed to remount cgroup v2"
        fi
    fi

    # Enable controllers in the root cgroup
    echo "+cpu +memory +io +pids" > /sys/fs/cgroup/cgroup.subtree_control

    # Create a cgroup for the user
    USER_CGROUP="/sys/fs/cgroup/$USER"
    mkdir -p "$USER_CGROUP"

    # Change ownership to the user
    chown "$USER":"$USER" "$USER_CGROUP"

    # Set appropriate permissions
    chmod 755 "$USER_CGROUP"

    # Switch to user context to enable controllers in their cgroup
    sudo -u "$USER" bash -c "echo '+cpu +memory +io +pids' > '$USER_CGROUP/cgroup.subtree_control'"

    log "cgroup v2 has been set up and delegated to user $USER"
}

# Function to check and display the current cgroup version and structure.
check_cgroup_version() {
    log "Checking cgroup version..."
    if [[ -f /proc/filesystems ]] && grep -q cgroup2 /proc/filesystems; then
        log "System is using cgroup v2."
    else
        log "cgroup v2 not found; please verify your system configuration."
    fi
    log "Current cgroup structure:"
    ls -l /sys/fs/cgroup
}
