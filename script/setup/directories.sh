#!/bin/bash
source ../config/config.sh

# Function to create necessary directories with proper permissions.
create_directories() {
    log "Creating necessary directories..."

    sudo mkdir -p "$DOWNLOAD_DIR" "$BUNDLE_DIR/rootfs" "$HOST_CONFIG_DIR" "$HOST_MEDIA_DIR"

    # Change ownership to the current user
    sudo chown -R "$(whoami):$(whoami)" "$DOWNLOAD_DIR" "$BUNDLE_DIR" "$HOST_CONFIG_DIR" "$HOST_MEDIA_DIR"

    # Set permissions
    chmod 755 "$DOWNLOAD_DIR" "$BUNDLE_DIR" "$BUNDLE_DIR/rootfs"
    chmod 755 "$HOST_CONFIG_DIR" "$HOST_MEDIA_DIR"

    # Verify directories are writable
    for dir in "$DOWNLOAD_DIR" "$BUNDLE_DIR" "$HOST_CONFIG_DIR" "$HOST_MEDIA_DIR"; do
        if [ ! -w "$dir" ]; then
            error_exit "Directory $dir is not writable. Check permissions or ownership."
        fi
    done

    log "Directories created and permissions verified."
}
