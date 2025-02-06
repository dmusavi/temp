precleanup() {
    log "Performing complete cleanup of cgroup v1 resources..."
    
    CGROUP_ROOT="/sys/fs/cgroup"
    
    controllers=($(find "$CGROUP_ROOT" -mindepth 1 -maxdepth 1 -type d -not -name 'cgroup' -exec basename {} \;))
    
    for controller in "${controllers[@]}"; do
        mount_point="$CGROUP_ROOT/$controller"
        
        if mountpoint -q "$mount_point"; then
            log "Cleaning up legacy cgroup v1 controller: $controller"
            
            # Move all processes back to the root cgroup for this controller.
            tasks_files=$(find "$mount_point" -type f -name "tasks")
            
            for tasks_file in $tasks_files; do
                while read -r pid; do
                    if [ -d "/proc/$pid" ]; then
                        echo "$pid" > "$mount_point/tasks" 2>/dev/null || true
                    fi
                done < "$tasks_file"
            done
            
            # Remove all empty child cgroups.
            find "$mount_point" -mindepth 1 -type d -exec rmdir {} \; 2>/dev/null || true
            
            # Unmount the cgroup v1 controller.
            if ! umount "$mount_point" 2>/dev/null; then
                if ! umount -l "$mount_point" 2>/dev/null; then
                    log "Warning: Could not unmount $mount_point; may require manual intervention"
                fi
            fi
        else
            log "Controller $controller is not mounted; skipping"
        fi
    done
    
    # Remove any leftover cgroup v1 directories.
    find "$CGROUP_ROOT" -mindepth 1 -maxdepth 1 -type d -not -name 'cgroup' -exec rmdir {} \; 2>/dev/null || true
    
    log "Legacy cgroup v1 controllers have been fully cleaned up"
}

# Function to set up cgroup v2 with delegation to the current user.
setup_cgroup_v2() {
    log "Setting up cgroup v2 with delegation to $USER..."

    CGROUP_ROOT="/sys/fs/cgroup"

    # Ensure cgroup v2 is mounted
    if ! mountpoint -q "$CGROUP_ROOT"; then
        mount -t cgroup2 none "$CGROUP_ROOT" || error_exit "Failed to mount cgroup v2"
    else
        if ! grep -qw "cgroup2" /proc/mounts; then
            log "Remounting $CGROUP_ROOT as cgroup2"
            umount "$CGROUP_ROOT"
            mount -t cgroup2 none "$CGROUP_ROOT" || error_exit "Failed to remount cgroup v2"
        fi
    fi

    # Enable controllers in the root cgroup
    echo "+cpu +memory +io +pids" > "$CGROUP_ROOT/cgroup.subtree_control"

    # Create a cgroup for the user
    USER_CGROUP="$CGROUP_ROOT/$USER"
    mkdir -p "$USER_CGROUP"

    # Change ownership and set permissions
    chown "$USER":"$USER" "$USER_CGROUP"
    chmod 755 "$USER_CGROUP"

    # Enable controllers in the user's cgroup
    if [ "$(id -un)" != "$USER" ]; then
        sudo -u "$USER" bash -c "echo '+cpu +memory +io +pids' > '$USER_CGROUP/cgroup.subtree_control'"
    else
        echo "+cpu +memory +io +pids" > "$USER_CGROUP/cgroup.subtree_control"
    fi

    log "cgroup v2 has been set up and delegated to user $USER"
}

# Function to check and display the current cgroup version and structure.
check_cgroup_version() {
    log "Checking cgroup version..."

    if grep -q 'cgroup2' /proc/filesystems; then
        log "System supports cgroup v2"
    else
        log "cgroup v2 not found; please verify your system configuration"
    fi

    log "Current cgroup mounts:"
    findmnt -t cgroup2
}
