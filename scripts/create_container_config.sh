# Function to create the container configuration (config.json)
create_container_config() {
  local bundle_dir="bundle"
  local config_file="$bundle_dir/config.json"

  mkdir -p "$bundle_dir"
  log "Creating minimal container configuration at $config_file..."
  cat << EOF > "$config_file"
{
  "ociVersion": "1.0.2",
  "process": {
    "user": { "uid": 0, "gid": 0 },
    "args": ["/bin/sh"],
    "env": ["PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", "LANG=C.UTF-8"],
    "cwd": "/",
    "terminal": true
  },
  "root": {
    "path": "rootfs"
  },
  "hostname": "minimal-container",
  "linux": {
    "namespaces": [
      { "type": "pid" },
      { "type": "mount" },
      { "type": "cgroup" }
    ]
  },
  "mounts": [
    { "destination": "/proc", "type": "proc", "source": "proc" }
  ]
}
EOF

  if [ $? -ne 0 ]; then
    log "Error: Failed to create $config_file"
    return 1
  fi

  sudo chmod 644 "$config_file" || {
    log "Error: Failed to set permissions for $config_file"
    return 1
  }

  if [ -f "$config_file" ]; then
    log "Minimal container config $config_file has been created successfully."
  else
    log "Error: $config_file was not created or does not exist."
    return 1
  fi
}
