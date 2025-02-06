#!/bin/bash

# Function to create necessary directories with proper permissions.
create_directories() {
    log "Creating necessary directories..."

    sudo mkdir -p "downloads" "rootfs" "config" "config/media"

    # Change ownership to the current user
    sudo chown -R "$(whoami):$(whoami)" "downloads" "rootfs" "config" "config/media"

    # Set permissions
    chmod 755 "downloads" "rootfs"
    chmod 755 "config" "config/media"

    # Verify directories are writable
    for dir in "downloads" "rootfs" "config" "config/media"; do
        if [ ! -w "$dir" ]; then
            error_exit "Directory $dir is not writable. Check permissions or ownership."
        fi
    done

    log "Directories created and permissions verified."
}
