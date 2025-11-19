# Linux VM Provisioning with Docker and Ansible

This project demonstrates provisioning a Linux virtual machine using **Docker** and configuring it with **Ansible**. The main goal is to **learn Ansible** in a simple and controlled environment.

---
## Milestone 0 – Environment Provisioning
## Provisioning Approach

I was presented with three options to provision a Linux VM:

- On-premises
- Cloud-based
- Virtualized

I chose the **Virtualized** option because it offers more control and simplicity, which is ideal for this learning project.

### Virtualized Options

Within the virtualized approach, there are several methods:

| Feature | VirtualBox VM | Multipass VM | Docker Container |
|---------|---------------|--------------|-----------------|
| **Setup** | Medium | Very easy | Very easy |
| **OS Isolation** | Full VM | Full VM | Shared kernel |
| **Systemd / Services** | ✅ Full | ✅ Full | ❌ Limited |
| **SSH Access** | ✅ Yes | ✅ Yes | ⚠ Needs setup |
| **Networking** | Manual | Auto IP | Port mapping |
| **Resource Use** | High | Moderate | Very low |
| **Startup Time** | Slow | Fast | Very fast |
| **Best for Ansible** | ✅ Full OS-level | ✅ Full OS-level | ⚠ Limited |
| **Running Apps (Grafana/Prometheus)** | ✅ Yes | ✅ Yes | ✅ Perfect |
| **Multiple Nodes** | ✅ Heavy | ✅ Easy | ✅ Easy, lightweight |

I considered **Multipass VM** and **Docker Container**. Both are quick and resource-friendly.  
I leaned toward Docker because of familiarity and future milestones involving Grafana and Prometheus. However, the primary goal is to learn Ansible. Multipass offers **full OS-level access** and **realistic networking**, but I chose Docker for simplicity and compatibility with WSL.

---

## Setting up the VM with Docker Container

### Prerequisites

- WSL2 installed
- Docker installed

### Pull the Ubuntu LTS Image

```bash
docker pull ubuntu:24.04
```

### Create a Dockerfile

Instead of manually configuring a VM with Python, Git, Docker, and SSH, I created a Docker image with everything preconfigured:

```dockerfile
FROM ubuntu:24.04

# Avoid prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# Update and install core tools
RUN apt update && \
    apt install -y \
        openssh-server \
        python3 python3-pip python3-apt \
        sudo git curl wget vim net-tools \
        apt-transport-https ca-certificates lsb-release gnupg && \
    mkdir /var/run/sshd && \
    echo 'root:root' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Optional: Install Docker CLI (not full Docker Engine)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt update && apt install -y docker-ce-cli

# Expose SSH
EXPOSE 22

# Start SSH daemon
CMD ["/usr/sbin/sshd", "-D"]
```

### Build the Docker Image

```bash
docker build -t ansible-node:latest .
```

### Create a Docker Compose File

`docker-compose.yml`:

```yaml
services:
  ansible-node:
    image: ansible-node:latest
    container_name: ansible-node
    ports:
      - "2222:22"
    tty: true
    restart: unless-stopped
```

### Start the Container

```bash
docker-compose up -d
```

Check the container status:

```bash
docker ps -a
```

---

## Connecting to the VM

### Connect via SSH

```bash
ssh root@127.0.0.1 -p 2222
# password: root
```

### Set up SSH Keys for Ansible

Generate a key on your local machine:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```

Copy the public key to the container:

```bash
ssh-copy-id -i ~/.ssh/id_rsa -p 2222 root@127.0.0.1
```

---

## Ansible Configuration

### Create Ansible Inventory

`inventory.ini`:

```ini
[local_nodes]
ansible-node ansible_host=127.0.0.1 ansible_port=2222 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa
```

### Test Connectivity

```bash
ansible -i inventory.ini local_nodes -m ping
```

Expected output:

```json
ansible-node | SUCCESS => {"changed": false, "ping": "pong"}
```

---

## VS Code Remote Development

### Installing the Remote SSH Extension

To connect VS Code directly to the container via SSH, install the Remote - SSH extension:

1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X)
3. Search for "Remote - SSH"
4. Install the extension by Microsoft

### Connecting to the Container

#### Method 1: WSL Connection

If you're working in WSL and want to connect to your WSL environment:

1. Look at the bottom-left corner of VS Code for the connection status indicator
2. Click on the status indicator (it shows your current connection type)
3. Select "Connect to WSL" from the dropdown menu

#### Method 2: SSH Connection to Container

To connect directly to the Docker container (or any other Machine):

1. Click on the connection status indicator in the bottom-left corner
2. Select "Connect to Host..." from the dropdown menu
3. Choose "127.0.0.1:2222" (or add it if not listed)
4. If you've set up SSH keys properly, you'll connect without a password
5. If not, you'll be prompted for the password (default: `root`)

Once connected, VS Code will open a new window running inside the container environment. This is particularly useful when you need to:
- Edit configuration files directly on the target system
- Set up and configure Grafana and Prometheus
- Debug applications running in the container
- Have a complete development environment within the provisioned VM

---

## Project Structure at Milestone 0

```
.
├── docker-compose.yml    # Container orchestration
├── Dockerfile           # VM image definition
├── inventory.ini        # Ansible inventory
└── readme.md           # This documentation
```
