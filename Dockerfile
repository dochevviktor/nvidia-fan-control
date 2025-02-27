# Use a base image with a newer GLIBC version (Debian 11+ or Ubuntu 22.04)
FROM nvidia/cuda:12.2.2-devel-ubuntu22.04 AS build

# Set working directory
WORKDIR /app

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    git \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Go
RUN wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz && \
    rm go1.21.6.linux-amd64.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"

# Copy source code
COPY . .

# Build the application
RUN go build -o nvidia_fan_control

# Use a minimal runtime image
FROM nvidia/cuda:12.2.2-runtime-ubuntu22.04

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libnvidia-compute-525 \
    && rm -rf /var/lib/apt/lists/*

# Copy the built application from the build stage
COPY --from=build /app/nvidia_fan_control .

# Copy the config file from the source
COPY --from=build /app/config.json .

# Ensure the NVIDIA libraries are available
ENV LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu"

# Explicitly set the user to root (UID 0)
USER root

# Run the application
CMD ["./nvidia_fan_control"]