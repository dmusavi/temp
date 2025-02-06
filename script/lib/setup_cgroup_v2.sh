#!/bin/bash
source ../config/config.sh

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
