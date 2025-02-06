#!/bin/bash

# Variables
EXPECTED_CHECKSUM="SHA256_CHECKSUM_HERE"   # Expected SHA256 checksum for verification (replace with actual checksum)
IMAGE_ID="arch-container"                  # Container ID for crun
NETNS_NAME="arch-netns"                    # Network namespace name
BRIDGE_NAME="br0"                          # Bridge name (brought up by init systemv ifup br0)
HOST_VETH_IP="10.0.20.1/24"                # IP address for the host's veth interface (with subnet mask)
BRIDGE_IP="10.10.10.14/24"                # IP address for the bridge network
CONTAINER_IP="10.0.20.2/24"               # IP address for the container within its network
HOST_PORT="8088"                           # Host port for container port forwarding
CONTAINER_PORT="80"                        # Container port

# Base directory needs adjustment for the new structure
BASE_DIR="."

# Configuration directories
HOST_CONFIG_DIR="$BASE_DIR/config"               # Directory for Nginx configuration on the host
HOST_NGINX_CONF="$HOST_CONFIG_DIR/nginx.conf"    # Path to Nginx configuration on the host
HOST_MEDIA_DIR="$HOST_CONFIG_DIR/media"          # Directory for media files to be served by Nginx on the host

# URLs and files for image downloading and verification
IMAGE_URL_ARCH="https://geo.mirror.pkgbuild.com/iso/2025.02.01/archlinux-bootstrap-2025.02.01-x86_64.tar.zst"
IMAGE_SIG_URL="https://geo.mirror.pkgbuild.com/iso/2025.02.01/archlinux-bootstrap-2025.02.01-x86_64.tar.zst.sig"
CHECKSUMS_URL="https://archlinux.org/iso/2025.02.01/sha256sums.txt"
IMAGE_FILE="archlinux-bootstrap-2025.02.01-x86_64.tar.zst"

# Directories for downloads and bundle
DOWNLOAD_DIR="$BASE_DIR/downloads"
BUNDLE_DIR="$BASE_DIR"
