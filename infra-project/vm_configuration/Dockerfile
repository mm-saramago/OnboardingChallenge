FROM ubuntu:24.04

# Avoid prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# Update and install core tools
RUN apt update && \
    apt install -y \
        openssh-server \
        python3 python3-pip python3-apt \
        sudo git curl wget vim net-tools \
        apt-transport-https ca-certificates lsb-release gnupg \
        cron && \
    mkdir /var/run/sshd && \
    echo 'root:root' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Optional: Install Docker CLI (not the full Docker Engine)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt update && apt install -y docker-ce-cli

RUN pip install --break-system-packages docker requests

# Create startup script to run both SSH and cron
RUN echo '#!/bin/bash\nservice cron start\n/usr/sbin/sshd -D' > /start.sh && \
    chmod +x /start.sh

# Expose SSH
EXPOSE 22

# Start both cron and SSH daemon
CMD ["/start.sh"]
