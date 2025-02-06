#!/bin/bash

# Source configuration
source ./config/config.sh

# Source utility functions
source ./lib/utils.sh
source ./lib/precleanup.sh
source ./lib/setup_cgroup_v2.sh
source ./lib/cleanup.sh
source ./lib/network.sh
source ./setup/dependencies.sh
source ./setup/directories.sh
source ./download/verify.sh

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

    echo "Container started with port forwarding from host $HOST_PORT to container $CONTAINER_PORT."
}

trap cleanup ERR EXIT
main "$@"
