#!/bin/bash
source ../config/config.sh

# Function to check required dependencies.
check_dependencies() {
    local deps=(crun sudo wget mount gpg sha256sum tar unzstd)
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error_exit "$cmd is not installed. Please install it before running this script."
        fi
    done

    # Check that crun's version is at least 1.0
    local crun_version
    crun_version=$(crun --version | head -n1 | awk '{print $3}')
    if ! printf '%s\n%s\n' "1.0" "$crun_version" | sort -V -C; then
        error_exit "crun version must be at least 1.0"
    fi
}
