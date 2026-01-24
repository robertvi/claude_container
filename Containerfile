FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    bubblewrap \
    socat \
    curl \
    sudo \
    git \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user 'claude' with UID 1000
RUN groupadd -g 1000 claude && \
    useradd -u 1000 -g 1000 -m -s /bin/bash claude

# Configure passwordless sudo for claude user
RUN echo 'claude ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/claude && \
    chmod 0440 /etc/sudoers.d/claude

# Switch to claude user for Claude Code installation
USER claude
WORKDIR /home/claude

# Install Claude Code CLI as the claude user (required for auto-updates)
RUN curl -fsSL https://storage.googleapis.com/anthropic-code-cli/install.sh | sh

# Add Claude Code to PATH
ENV PATH="/home/claude/.local/bin:${PATH}"

# Set working directory to the shared workspace
WORKDIR /workspace

# Keep container running
CMD ["sleep", "infinity"]
