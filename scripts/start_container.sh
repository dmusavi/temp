#!/bin/bash

# Function to start the container.
start_container() {
    log "Starting container $IMAGE_ID..."
    sudo ip netns exec "$NETNS_NAME" crun run -b "$HOME/downloads/media/config/nginx" "$IMAGE_ID" &
    local pid=$!
    echo "$pid" > "$HOME/downloads/media/config/nginx/container_$IMAGE_ID.pid"
}
