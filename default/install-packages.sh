#!/bin/bash
apt-get update
apt-get install -y \
    bubblewrap \
    socat \
    curl \
    nano \
    sudo \
    build-essential \
    ca-certificates
rm -rf /var/lib/apt/lists/*
