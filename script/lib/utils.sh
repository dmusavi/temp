#!/bin/bash

# Function to log informational messages.
log() {
    echo "[INFO] $1"
}

# Function to handle errors by printing a message and exiting.
error_exit() {
    echo "[ERROR] $1" >&2
    exit 1
}
