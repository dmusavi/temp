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
    if sudo ip link show "$HOST_VETH_NAME" &>/dev/null || sudo ip netns exec "$NETNS_NAME" ip link show "$CONTAINER_VETH_NAME" &>/dev/null; then
        log "Removing existing veth interfaces..."
        sudo ip link delete "$HOST_VETH_NAME" type veth || true
    fi

    # Create veth pair
    log "Creating veth pair $HOST_VETH_NAME <-> $CONTAINER_VETH_NAME..."
    sudo ip link add "$HOST_VETH_NAME" type veth peer name "$CONTAINER_VETH_NAME"

    # Move container side of veth into the network namespace
    sudo ip link set "$CONTAINER_VETH_NAME" netns "$NETNS_NAME"

    # Assign IP addresses and bring up interfaces

    # Inside the container (network namespace)
    sudo ip netns exec "$NETNS_NAME" ip addr add "$CONTAINER_IP" dev "$CONTAINER_VETH_NAME"
    sudo ip netns exec "$NETNS_NAME" ip link set "$CONTAINER_VETH_NAME" up
    sudo ip netns exec "$NETNS_NAME" ip link set lo up

    # On the host
    sudo ip addr add "$HOST_VETH_IP" dev "$HOST_VETH_NAME"
    sudo ip link set "$HOST_VETH_NAME" up

    # Set up default route in the container
    CONTAINER_GATEWAY="${HOST_VETH_IP%/*}"
    sudo ip netns exec "$NETNS_NAME" ip route add default via "$CONTAINER_GATEWAY" dev "$CONTAINER_VETH_NAME"

    # Optional: Add route on host to reach container from other interfaces (e.g., br0)
    # This allows the host to route traffic to the container's subnet
    CONTAINER_SUBNET="${CONTAINER_IP%.*}.0/24"
    sudo ip route add "$CONTAINER_SUBNET" dev "$HOST_VETH_NAME"

    # Verify connectivity between host and container
    log "Verifying connectivity between host and container..."

    # Extract IP addresses without subnet masks
    CONTAINER_IP_NO_MASK="${CONTAINER_IP%/*}"
    HOST_VETH_IP_NO_MASK="${HOST_VETH_IP%/*}"

    # Ping from host to container
    if ping -c 1 -W 1 "$CONTAINER_IP_NO_MASK" &>/dev/null; then
        log "Host can ping container IP $CONTAINER_IP_NO_MASK"
    else
        log "Error: Host cannot ping container IP $CONTAINER_IP_NO_MASK"
        exit 1
    fi

    # Ping from container to host's veth interface
    if sudo ip netns exec "$NETNS_NAME" ping -c 1 -W 1 "$HOST_VETH_IP_NO_MASK" &>/dev/null; then
        log "Container can ping host veth IP $HOST_VETH_IP_NO_MASK"
    else
        log "Error: Container cannot ping host veth IP $HOST_VETH_IP_NO_MASK"
        exit 1
    fi

    # Ping from container to host's br0 interface (if needed)
    HOST_BRIDGE_IP_NO_MASK="${BRIDGE_IP%/*}"
    if sudo ip netns exec "$NETNS_NAME" ping -c 1 -W 1 "$HOST_BRIDGE_IP_NO_MASK" &>/dev/null; then
        log "Container can ping host bridge IP $HOST_BRIDGE_IP_NO_MASK"
    else
        log "Error: Container cannot ping host bridge IP $HOST_BRIDGE_IP_NO_MASK"
        # Depending on your needs, you may choose to exit here or not
    fi

    log "Network setup complete."
}
