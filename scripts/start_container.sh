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

    # Create console socket directory and file
    console_socket="/tmp/console.sock"
    sudo rm -f "$console_socket"  # Remove any existing socket
    sudo mkfifo "$console_socket"  # Create a FIFO for the console socket
    sudo chmod 777 "$console_socket"  # Temporary permissions for testing

    # Start a background process to keep the FIFO open
    (cat < "$console_socket" > /dev/null &)  # This keeps the FIFO open

    # Run the container
    sudo crun run --bundle="$(pwd)/$bundle_dir" --console-socket="$console_socket" --detach "$IMAGE_ID" || {
        log "Failed to create and start container $IMAGE_ID"
        exit 1
    }

    # Retrieve the container PID without using jq
    container_pid=$(sudo crun list | awk -v id="$IMAGE_ID" '$1 == id {print $2}')
    if [[ -n "$container_pid" ]]; then
        log "Container $IMAGE_ID started with PID $container_pid"
    else
        log "Error: Failed to retrieve container PID"
        exit 1
    fi

    log "Container $IMAGE_ID is up and running."
}
