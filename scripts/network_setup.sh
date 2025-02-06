#!/bin/bash

# Function to set up networking (network namespace and veth pair).
setup_networking() {
    log "Setting up network..."

    # Create network namespace if it doesn't exist
    if ! sudo ip netns list | grep -qw "$NETNS_NAME"; then
        log "Creating network namespace $NETNS_NAME..."
        sudo ip netns add "$NETNS_NAME"
    fi

    # Create veth pair if it doesn't exist
    if ! ip link show veth1 &>/dev/null; then
        log "Creating veth pair..."
        sudo ip link add veth0 type veth peer name veth1
        sudo ip link set veth0 netns "$NETNS_NAME"
        sudo ip link set veth1 master "$BRIDGE_NAME"
        sudo ip link set veth1 up
    fi

    sudo ip netns exec "$NETNS_NAME" ip addr add "$CONTAINER_IP" dev veth0
    sudo ip netns exec "$NETNS_NAME" ip link set veth0 up
}
