#!/bin/bash

# Function to start the container.
start_container() {
    local bundle_dir="."
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
    sudo crun create --bundle "$bundle_dir" "$IMAGE_ID" || {
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
        echo "$container_pid" > "$bundle_dir/container_${IMAGE_ID}.pid"
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

    # Since we cannot perform port forwarding, verify that Nginx is accessible directly
    CONTAINER_IP_NO_MASK="${CONTAINER_IP%/*}"
    log "Verifying Nginx accessibility on container IP $CONTAINER_IP_NO_MASK and port $CONTAINER_PORT..."

    # Wait a few seconds for Nginx to start inside the container
    sleep 3

    # Attempt to access Nginx from the host
    if curl -s --head --connect-timeout 5 "http://$CONTAINER_IP_NO_MASK:$CONTAINER_PORT" | grep -q "200 OK"; then
        log "Success: Nginx in container $IMAGE_ID is responding."
    else
        log "Error: Nginx in container $IMAGE_ID is not responding."
        exit 1
    fi

    log "Container $IMAGE_ID is up and running."
}
