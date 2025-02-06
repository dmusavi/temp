#!/bin/bash

# Variables
EXPECTED_CHECKSUM="SHA256_CHECKSUM_HERE"   # Expected SHA256 checksum for verification (replace with actual checksum)
IMAGE_ID="arch-container"                  # Container ID for crun
NETNS_NAME="arch-netns"                    # Network namespace name
BRIDGE_NAME="br0"                          # Bridge name (brought up by init system ifup br0)
BRIDGE_IP="10.10.10.14/24"                 # IP address for the bridge network
CONTAINER_IP="10.0.20.1/24"                # IP address for the container within its network
HOST_PORT="8088"                           # Host port for container port forwarding
CONTAINER_PORT="80"                        # Container port

# Project base directory (relative to the repository root)
PROJECT_DIR="$(pwd)"                        # Dynamically set to the repository root
BASE_DIR="$PROJECT_DIR/script"              # Base directory for all script-related files within the repository
HOST_CONFIG_DIR="$BASE_DIR/config"          # Directory for Nginx configuration files within the repository
HOST_NGINX_CONF="$HOST_CONFIG_DIR/nginx.conf"  # Path to Nginx configuration file within the repository
HOST_MEDIA_DIR="$HOST_CONFIG_DIR/media"     # Directory for media files to be served by Nginx within the repository

IMAGE_URL_ARCH="https://geo.mirror.pkgbuild.com/iso/2025.02.01/archlinux-bootstrap-2025.02.01-x86_64.tar.zst"
IMAGE_SIG_URL="https://geo.mirror.pkgbuild.com/iso/2025.02.01/archlinux-bootstrap-2025.02.01-x86_64.tar.zst.sig"
CHECKSUMS_URL="https://archlinux.org/iso/2025.02.01/sha256sums.txt"

IMAGE_FILE="archlinux-bootstrap-2025.02.01-x86_64.tar.zst"
DOWNLOAD_DIR="$BASE_DIR/downloads"         # Directory for downloaded files within the repository
BUNDLE_DIR="$BASE_DIR/bundle"              # Directory for the container bundle within the repository
