#!/bin/bash
source ../config/config.sh

# Modified cleanup function to handle cgroup v2 cleanup.
cleanup() {
    local exit_code=$?
    log "Performing cleanup..."

    # Remove user's cgroup directory if it exists
    USER_CGROUP="/sys/fs/cgroup/$USER"
    if [ -d "$USER_CGROUP" ]; then
        sudo rmdir "$USER_CGROUP" 2>/dev/null || true
    fi

    # Existing cleanup code:
    if sudo crun list | grep -qw "$IMAGE_ID"; then
        sudo crun stop "$IMAGE_ID" 2>/dev/null || true
        sudo crun delete -f "$IMAGE_ID" 2>/dev/null || true
    fi

    if sudo ip netns list | grep -qw "$NETNS_NAME"; then
        sudo ip netns del "$NETNS_NAME" 2>/dev/null || true
    fi

    if ip link show veth1 &>/dev/null; then
        sudo ip link delete veth1 2>/dev/null || true
    fi

    sudo rm -rf "$DOWNLOAD_DIR" "$BUNDLE_DIR"
    rm -f "$BASE_DIR/container_$IMAGE_ID.pid"

    exit "$exit_code"
}
