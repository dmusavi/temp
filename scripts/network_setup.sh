#!/bin/bash

# Function to set up networking (network namespace and veth pair).
setup_networking() {
    log "Setting up network..."

    # Create network namespace if it doesn't exist
    if ! sudo ip netns list | grep -qw "$NETNS_NAME"; then
        log "Creating network namespace $NETNS_NAME..."
        sudo ip netns add "$NETNS_NAME" || { log "Error: Failed to create network namespace $NETNS_NAME"; exit 1; }
    fi

    # Remove existing veth interfaces if they exist
    if sudo ip link show "$HOST_VETH_NAME" &>/dev/null; then
        log "Removing existing host veth interface $HOST_VETH_NAME..."
        sudo ip link delete "$HOST_VETH_NAME" type veth || { log "Warning: Failed to remove $HOST_VETH_NAME"; }
    fi

    # Check if the container veth interface exists in the namespace
    if sudo ip netns exec "$NETNS_NAME" ip link show "$CONTAINER_VETH_NAME" &>/dev/null; then
        log "Removing existing container veth interface $CONTAINER_VETH_NAME in namespace $NETNS_NAME..."
        sudo ip netns exec "$NETNS_NAME" ip link delete "$CONTAINER_VETH_NAME" || { log "Warning: Failed to remove $CONTAINER_VETH_NAME from namespace"; }
    fi

    # Remove existing IP addresses on host's veth interface (if any)
    if ip addr show "$HOST_VETH_NAME" &>/dev/null; then
        log "Flushing IP addresses on $HOST_VETH_NAME..."
        sudo ip addr flush dev "$HOST_VETH_NAME" || { log "Warning: Failed to flush IPs on $HOST_VETH_NAME"; }
    fi

    # Remove any existing IP address assignments for $HOST_VETH_IP on other interfaces
    EXISTING_INT=$(ip addr show | awk '/'"${HOST_VETH_IP%/*}"'/{print $NF}')
    if [[ -n "$EXISTING_INT" && "$EXISTING_INT" != "$HOST_VETH_NAME" ]]; then
        log "IP $HOST_VETH_IP is already assigned to interface $EXISTING_INT. Removing it."
        sudo ip addr del "$HOST_VETH_IP" dev "$EXISTING_INT" || { log "Warning: Failed to remove $HOST_VETH_IP from $EXISTING_INT"; }
    fi

    # Create veth pair
    log "Creating veth pair $HOST_VETH_NAME <-> $CONTAINER_VETH_NAME..."
    sudo ip link add "$HOST_VETH_NAME" type veth peer name "$CONTAINER_VETH_NAME" || { log "Error: Failed to create veth pair $HOST_VETH_NAME <-> $CONTAINER_VETH_NAME"; exit 1; }

    # Move container side of veth into the network namespace
    log "Moving container side of veth interface $CONTAINER_VETH_NAME into network namespace $NETNS_NAME..."
    sudo ip link set "$CONTAINER_VETH_NAME" netns "$NETNS_NAME" || { log "Error: Failed to move $CONTAINER_VETH_NAME into network namespace"; exit 1; }

    # Assign IP addresses and bring up interfaces
    log "Assigning IP addresses and bringing up interfaces..."

    # Inside the container (network namespace)
    sudo ip netns exec "$NETNS_NAME" bash -c "
        if ip addr show dev $CONTAINER_VETH_NAME | grep -qw '${CONTAINER_IP%/*}'; then 
            echo 'IP $CONTAINER_IP is already assigned to $CONTAINER_VETH_NAME inside namespace $NETNS_NAME. Removing it.'
            ip addr del $CONTAINER_IP dev $CONTAINER_VETH_NAME || echo 'Warning: Failed to remove existing IP from $CONTAINER_VETH_NAME'
        fi
        echo 'Assigning IP address $CONTAINER_IP to $CONTAINER_VETH_NAME inside namespace $NETNS_NAME...'
        ip addr add $CONTAINER_IP dev $CONTAINER_VETH_NAME || echo 'Error: Failed to assign IP to $CONTAINER_VETH_NAME'
        ip link set $CONTAINER_VETH_NAME up || echo 'Error: Failed to bring up $CONTAINER_VETH_NAME'
        ip link set lo up || echo 'Error: Failed to bring up loopback'
    " || { log "Error: Failed to configure network inside namespace"; exit 1; }

    # On the host
    log "Assigning IP $HOST_VETH_IP to host veth interface $HOST_VETH_NAME..."
    sudo ip addr add "$HOST_VETH_IP" dev "$HOST_VETH_NAME" || { log "Error: Failed to assign IP $HOST_VETH_IP to host veth interface"; exit 1; }
    sudo ip link set "$HOST_VETH_NAME" up || { log "Error: Failed to bring up host veth interface"; exit 1; }

    # Set up default route in the container
    log "Setting up default route in the container..."
    CONTAINER_GATEWAY="${HOST_VETH_IP%/*}"
    sudo ip netns exec "$NETNS_NAME" ip route add default via "$CONTAINER_GATEWAY" dev "$CONTAINER_VETH_NAME" || { log "Error: Failed to set up default route in the container"; exit 1; }

    # Add route on host to reach container from other interfaces
    CONTAINER_SUBNET="${CONTAINER_IP%.*}.0/24"
    log "Checking if route to $CONTAINER_SUBNET exists..."
    if ! ip route show | grep -qw "$CONTAINER_SUBNET"; then
        log "Adding route to $CONTAINER_SUBNET on the host..."
        sudo ip route add "$CONTAINER_SUBNET" dev "$HOST_VETH_NAME" || { log "Error: Failed to add route to $CONTAINER_SUBNET"; exit 1; }
    else
        log "Route to $CONTAINER_SUBNET already exists."
    fi

    # Verify connectivity between host and container
    log "Verifying connectivity between host and container..."

    # Extract IP addresses without subnet masks
    CONTAINER_IP_NO_MASK="${CONTAINER_IP%/*}"
    HOST_VETH_IP_NO_MASK="${HOST_VETH_IP%/*}"

    # Ping from host to container
    log "Pinging container IP $CONTAINER_IP_NO_MASK from host..."
    if ping -c 1 -W 1 "$CONTAINER_IP_NO_MASK" &>/dev/null; then
        log "Host can ping container IP $CONTAINER_IP_NO_MASK"
    else
        log "Error: Host cannot ping container IP $CONTAINER_IP_NO_MASK"
        exit 1
    fi

    # Ping from container to host's veth interface
    log "Pinging host veth IP $HOST_VETH_IP_NO_MASK from container..."
    if sudo ip netns exec "$NETNS_NAME" ping -c 1 -W 1 "$HOST_VETH_IP_NO_MASK" &>/dev/null; then
        log "Container can ping host veth IP $HOST_VETH_IP_NO_MASK"
    else
        log "Error: Container cannot ping host veth IP $HOST_VETH_IP_NO_MASK"
        exit 1
    fi

    # Ping from container to host's br0 interface (if needed)
    HOST_BRIDGE_IP_NO_MASK="${BRIDGE_IP%/*}"
    log "Pinging host bridge IP $HOST_BRIDGE_IP_NO_MASK from container..."
    if sudo ip netns exec "$NETNS_NAME" ping -c 1 -W 1 "$HOST_BRIDGE_IP_NO_MASK" &>/dev/null; then
        log "Container can ping host bridge IP $HOST_BRIDGE_IP_NO_MASK"
    else
        log "Warning: Container cannot ping host bridge IP $HOST_BRIDGE_IP_NO_MASK"
        # Depending on your needs, you may choose to exit here or not
    fi

    log "Network setup complete."
}
