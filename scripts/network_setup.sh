#!/bin/bash

# Function to set up networking (network namespace and veth pair).
setup_networking() {
    log "Setting up network..."

    # Create network namespace if it doesn't exist
    if ! sudo ip netns list | grep -qw "$NETNS_NAME"; then
        log "Creating network namespace $NETNS_NAME..."
        sudo ip netns add "$NETNS_NAME"
    fi

    # Remove existing veth interfaces if they exist
    if sudo ip link show veth0 &>/dev/null || sudo ip link show veth1 &>/dev/null; then
        log "Removing existing veth interfaces..."
        sudo ip link delete veth0 type veth || true
        sudo ip link delete veth1 type veth || true
    fi

    # Create veth pair
    log "Creating veth pair veth0 <-> veth1..."
    sudo ip link add veth0 type veth peer name veth1

    # Move veth0 into the network namespace
    sudo ip link set veth0 netns "$NETNS_NAME"

    # Assign IP addresses
    sudo ip netns exec "$NETNS_NAME" ip addr add "$CONTAINER_IP" dev veth0
    sudo ip netns exec "$NETNS_NAME" ip link set veth0 up
    sudo ip netns exec "$NETNS_NAME" ip link set lo up

    sudo ip addr add "$BRIDGE_IP" dev veth1
    sudo ip link set veth1 up

    # Set up default route in the container
    CONTAINER_GATEWAY="${BRIDGE_IP%/*}"
    sudo ip netns exec "$NETNS_NAME" ip route add default via "$CONTAINER_GATEWAY"

    # Verify connectivity between host and container
    log "Verifying connectivity between host and container..."

    # Extract IP addresses without subnet masks
    CONTAINER_IP_NO_MASK="${CONTAINER_IP%/*}"
    BRIDGE_IP_NO_MASK="${BRIDGE_IP%/*}"

    if ping -c 1 -W 1 "$CONTAINER_IP_NO_MASK" &>/dev/null; then
        log "Host can ping container IP $CONTAINER_IP_NO_MASK"
    else
        log "Error: Host cannot ping container IP $CONTAINER_IP_NO_MASK"
        exit 1
    fi

    if sudo ip netns exec "$NETNS_NAME" ping -c 1 -W 1 "$BRIDGE_IP_NO_MASK" &>/dev/null; then
        log "Container can ping bridge IP $BRIDGE_IP_NO_MASK"
    else
        log "Error: Container cannot ping bridge IP $BRIDGE_IP_NO_MASK"
        exit 1
    fi

    log "Network setup complete."
}
