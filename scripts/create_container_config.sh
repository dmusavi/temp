# Function to create the container configuration (config.json)
create_container_config() {
  local bundle_dir="bundle"
  local config_file="$bundle_dir/config.json"

  mkdir -p "$bundle_dir"
  log "Creating container configuration at $config_file..."
  cat << EOF > "$config_file"
{
  "ociVersion": "1.0.2",
  "process": {
    "user": { "uid": 1000, "gid": 1000 },
    "args": ["/usr/bin/nginx", "-g", "daemon off;"],
    "env": [
      "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
      "LANG=C.UTF-8"
    ],
    "cwd": "/",
    "capabilities": {
      "bounding": ["CAP_CHOWN", "CAP_NET_BIND_SERVICE"],
      "effective": ["CAP_CHOWN", "CAP_NET_BIND_SERVICE"]
    },
    "rlimits": [
      { "type": "RLIMIT_NOFILE", "hard": 1024, "soft": 1024 }
    ],
    "terminal": false
  },
  "root": {
    "path": "rootfs",
    "readonly": false
  },
  "hostname": "arch-container",
  "linux": {
    "namespaces": [
      { "type": "pid" },
      { "type": "mount" },
      { "type": "network", "path": "/var/run/netns/$NETNS_NAME" },
      { "type": "cgroup" }
    ],
    "resources": {
      "memory": { "limit": 512000000 },
      "cpu": { "weight": 1024 }
    },
    "cgroupsPath": "/$USER",
    "seccomp": {
      "defaultAction": "SCMP_ACT_ERRNO",
      "architectures": ["SCMP_ARCH_X86_64"],
      "syscalls": [
        {
          "names": [
            "accept4", "bind", "clone", "close", "connect",
            "epoll_create1", "epoll_ctl", "epoll_wait", "exit",
            "exit_group", "fstat", "futex", "getcwd", "getdents64",
            "getpid", "ioctl", "listen", "lseek", "mkdir", "mmap",
            "mount", "open", "openat", "pipe2", "read", "recv",
            "recvfrom", "rt_sigaction", "rt_sigprocmask", "rt_sigreturn",
            "select", "send", "sendto", "set_robust_list", "set_tid_address",
            "socket", "stat", "write"
          ],
          "action": "SCMP_ACT_ALLOW"
        }
      ]
    }
  },
  "mounts": [
    { "destination": "/proc", "type": "proc", "source": "proc" },
    { "destination": "/dev", "type": "tmpfs", "source": "tmpfs", "options": ["nosuid", "strictatime", "mode=755", "size=65536k"] },
    { "destination": "/dev/pts", "type": "devpts", "source": "devpts", "options": ["nosuid", "noexec", "newinstance", "ptmxmode=0666", "mode=0620"] },
    { "destination": "/sys", "type": "sysfs", "source": "sysfs", "options": ["nosuid", "noexec", "nodev", "ro"] },
    { "destination": "/etc/nginx/nginx.conf", "source": "config/nginx.conf", "type": "bind", "options": ["ro", "rbind"] },
    { "destination": "/usr/share/nginx/html", "source": "/home/d/media", "type": "bind", "options": ["ro", "rbind"] }
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
    log "Container config $config_file has been created successfully."
  else
    log "Error: $config_file was not created or does not exist."
    return 1
  fi
}
