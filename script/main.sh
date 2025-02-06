#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source utility scripts
source scripts/utils.sh
source scripts/cgroup_setup.sh
source scripts/network_setup.sh
source scripts/cleanup.sh
source scripts/check_dependencies.sh
source scripts/create_directories.sh
source scripts/download_verify_image.sh
source scripts/create_nginx_config.sh
source scripts/create_container_config.sh
source scripts/start_container.sh

# Configuration
source config/config.sh  # Here you can define variables if needed

main() {
    precleanup
    setup_cgroup_v2
    check_dependencies
    create_directories
    download_verify_image
    create_nginx_config
    create_container_config
    setup_networking
    check_cgroup_version
    start_container
    
    log "Container started with port forwarding from host $HOST_PORT to container $CONTAINER_PORT."
}

# Trap for cleanup on exit
trap cleanup EXIT

# Main function invocation
main "$@"
