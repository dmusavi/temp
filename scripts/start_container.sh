#!/bin/bash

# Function to start the container.
start_container() {
    local bundle_dir="bundle" # Assuming 'bundle' is at the root of the git repo
    log "Starting container $IMAGE_ID..."

    # Remove existing container if it exists
    if sudo crun list | grep -qw "$IMAGE_ID"; then
        log "Deleting existing container $IMAGE_ID..."
        sudo crun delete --force "$IMAGE_ID" || {
            log "Failed to delete existing container"
            exit 1
        }
    fi

    # Create the container
    sudo crun create --bundle "$(pwd)/$bundle_dir" "$IMAGE_ID" || {
        log "Failed to create container $IMAGE_ID"
        exit 1
    }

    # Start the container
    sudo crun start "$IMAGE_ID" || {
        log "Failed to start container $IMAGE_ID"
        exit 1
    }

    # Retrieve the container PID without using jq
    container_pid=$(sudo crun list | awk -v id="$IMAGE_ID" '$1 == id {print $2}')
    if [[ -n "$container_pid" ]]; then
        echo "$container_pid" > "$(pwd)/$bundle_dir/container_${IMAGE_ID}.pid"
        log "Container $IMAGE_ID started with PID $container_pid"
    else
        log "Error: Failed to retrieve container PID"
        exit 1
    fi

    # Verify that the container is running
    container_status=$(sudo crun list | awk -v id="$IMAGE_ID" '$1 == id {print $NF}')
    if [[ "$container_status" != "RUNNING" ]]; then
        log "Error: Container $IMAGE_ID is not running. Status: $container_status"
        exit 1
    fi

    # Connect to the container
    log "Connecting to the container..."
    sudo crun exec "$IMAGE_ID" /bin/sh

    log "Container $IMAGE_ID is up and running."
}
