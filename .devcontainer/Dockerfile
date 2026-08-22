FROM thyrlian/android-sdk:latest

# Create and set permissions for workspace
RUN mkdir -p /workspace/.gradle && \
    chmod -R 777 /workspace/.gradle

# Additional VS Code Dev Container specific setup
RUN apt-get update && apt-get install -y \
    git \
    openssh-client \
    curl \
    android-tools-adb \
    && apt-get clean

# Task runner used by every workflow in the justfile
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh \
    | bash -s -- --to /usr/local/bin

# Use the provided helper script to accept licenses
RUN /opt/license-accepter.sh

WORKDIR /workspace