temp/
├── README.md
├── script/
│   ├── main.sh
│   ├── config/
│   │   ├── vars.sh
│   │   ├── nginx.conf
│   │   └── container.json
│   ├── lib/
│   │   ├── cgroup.sh
│   │   ├── network.sh
│   │   └── utils.sh
│   ├── setup/
│   │   ├── dependencies.sh
│   │   └── directories.sh
│   ├── download/
│   │   └── verify.sh
│   └── data/  # All dynamically created folders go here
│       ├── config/
│       │   └── nginx/
│       │       ├── nginx.conf
│       │       └── media/
│       ├── downloads/
│       └── rootfs/
