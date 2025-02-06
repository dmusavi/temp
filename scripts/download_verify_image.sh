#!/bin/bash

# Function to download and verify the Arch Linux bootstrap image.
download_verify_image() {
    mkdir -p "downloads"

    log "Downloading Arch Linux bootstrap tarball..."
    wget -O "downloads/$IMAGE_FILE" "$IMAGE_URL_ARCH" || error_exit "Failed to download $IMAGE_URL_ARCH"

    log "Downloading signature file..."
    wget -O "downloads/$(basename "$IMAGE_FILE").sig" "$IMAGE_SIG_URL" || error_exit "Failed to download $IMAGE_SIG_URL"

    log "Downloading sha256sums.txt..."
    wget -O "downloads/sha256sums.txt" "$CHECKSUMS_URL" || error_exit "Failed to download $CHECKSUMS_URL"

    # Extract the expected SHA256 checksum from the checksum file.
    EXPECTED_CHECKSUM=$(grep "$(basename "$IMAGE_FILE")" "downloads/sha256sums.txt" | awk '{print $1}')
    if [ -z "$EXPECTED_CHECKSUM" ]; then
        error_exit "Could not find expected SHA256 checksum for $IMAGE_FILE in sha256sums.txt."
    fi

    ACTUAL_CHECKSUM=$(sha256sum "downloads/$IMAGE_FILE" | awk '{print $1}')
    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        error_exit "Checksum mismatch: expected $EXPECTED_CHECKSUM but got $ACTUAL_CHECKSUM."
    fi

    log "Checksum verified successfully."

    log "Verifying the signature of the bootstrap tarball using GnuPG..."
    gpg --verify "downloads/$(basename "$IMAGE_FILE").sig" "downloads/$IMAGE_FILE" || error_exit "GPG signature verification failed."

    mkdir -p "rootfs"

    log "Extracting Arch Linux bootstrap tarball into rootfs..."
    tar --use-compress-program=unzstd -xpf "downloads/$IMAGE_FILE" -C "rootfs" --strip-components=1 || error_exit "Extraction failed."

    log "Arch Linux bootstrap rootfs is ready."
}
