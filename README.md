# Linux VM Provisioning with Docker and Ansible

### m0 Architecture
![Architecture Diagram](images/m0.png)

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

---
## Milestone 1 - Ansible Setup

### m1 Architecture
![Architecture Diagram](images/m1.png)

### Ansible Configuration

#### ansible.cfg

Created the Ansible configuration file to set up project paths and disable unnecessary warnings:

```ini
[defaults]
inventory = ./inventory/inventory.ini
roles_path = ./roles
host_key_checking = False
retry_files_enabled = False
deprecation_warnings = False
```

- `inventory`: Points to the inventory file location
- `roles_path`: Defines where to find Ansible roles
- `host_key_checking`: Disabled for development environment
- `retry_files_enabled`: Disabled to avoid clutter
- `deprecation_warnings`: Disabled for cleaner output

#### playbooks/site.yml

Created the main playbook that executes roles on defined hosts:

```yaml
---
- name: Configure local_nodes
  hosts: local_nodes
  become: yes
  roles:
    - moon-buggy
```

### Creating the moon-buggy Role

Following Ansible role best practices, I created a role to install the moon-buggy game:

#### defaults/main.yml

```yaml
---
package_name: moon-buggy
```

#### tasks/main.yml

```yaml
---
- name: Install moon-buggy game
  apt:
    name: "{{ package_name }}"
    state: present
    update_cache: yes
```

**Module Parameters Explained:**
- `apt`: Package manager module for Debian/Ubuntu
- `name`: Name of the package to install (using variable from defaults)
- `state: present`: Ensures the package is installed
- `update_cache: yes`: Runs `apt-get update` before installation

### Project Restructuring

Following Ansible best practices, I restructured the project to separate infrastructure and configuration management:

```
projeto/
├── ansible-project/
│   ├── ansible.cfg
│   ├── inventory/
│   │   └── inventory.ini
│   ├── playbooks/
│   │   └── site.yml
│   └── roles/
│       └── moon-buggy/
│           ├── defaults/
│           │   └── main.yml
│           └── tasks/
│               └── main.yml
│
├── infra-project/
│   ├── docker-compose.yml
│   └── Dockerfile
│
└── readme.md
```

### Running the Playbook

From the `ansible-project` directory, execute the playbook:

```bash
ansible-playbook playbooks/site.yml
```

### Verification

SSH into the container and verify the package installation:

```bash
ssh root@127.0.0.1 -p 2222
dpkg -l | grep moon-buggy
```

The command should show that the moon-buggy package is successfully installed.

---

## Milestone 2 - Monitoring and Visualization

### m2 Architecture
![Architecture Diagram](images/m2.png)

### Prepare docker image with new services

In this new Milestone cronjob was needed to execute periodically metrics. The ubuntu docker images does not cronjob installed, so we need to pre-install it on the Dockerfile and also enable the service.

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
```

After recreating we are ready to start the milestone

### Write a script to gather CPU, memory, disk, and uptime metrics

#### Overview

This milestone implements a comprehensive monitoring stack using Docker containers orchestrated by Ansible. The solution collects system metrics (CPU, memory, disk usage), stores them in Prometheus, and visualizes them through Grafana dashboards.

#### Architecture

The monitoring solution consists of:

- **Custom metrics collection script** running via cron jobs
- **Prometheus** for metrics storage and collection
- **Node Exporter** for system metrics exposure
- **Grafana** for data visualization and dashboards
- **Automated deployment** via Ansible playbooks

### Metrics Collection Implementation

#### System Metrics Script

Created `system-metrics.sh` to collect CPU, memory, and disk metrics:

```bash
#!/bin/bash
# Generate system metrics for Prometheus textfile collector

METRICS_DIR="/var/lib/node_exporter/textfile_collector"
METRICS_FILE="$METRICS_DIR/system_metrics.prom"

mkdir -p "$METRICS_DIR"

# CPU Usage (percentage)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print 100-$1}')

# Memory Usage (percentage)
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.2f", ($3/$2) * 100.0}')

# Disk Usage (percentage) for root filesystem
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

# Generate Prometheus metrics
cat > "$METRICS_FILE" << EOF
# HELP system_cpu_usage_percent System CPU usage percentage
# TYPE system_cpu_usage_percent gauge
system_cpu_usage_percent $CPU_USAGE

# HELP system_memory_usage_percent System memory usage percentage
# TYPE system_memory_usage_percent gauge
system_memory_usage_percent $MEMORY_USAGE

# HELP system_disk_usage_percent System disk usage percentage
# TYPE system_disk_usage_percent gauge
system_disk_usage_percent $DISK_USAGE
EOF
```

**Key Features:**

- Collects CPU usage using `top` command
- Calculates memory usage percentage from `/proc/meminfo` via `free`
- Monitors root filesystem disk usage with `df`
- Outputs metrics in Prometheus format compatible with textfile collector
- Creates metrics directory automatically if it doesn't exist

#### Sub-minute Collection Runner

Implemented `subminute_runner.sh` for frequent metric collection:

```bash
#!/bin/bash
# Run system metrics collection every 10 seconds for 1 minute

for i in {1..6}; do
    /opt/metrics/system-metrics.sh
    if [ $i -lt 6 ]; then
        sleep 10
    fi
done
```

This script runs the metrics collection 6 times with 10-second intervals, providing sub-minute granularity.

#### Cron Job Configuration

Configured automated execution via cron:

```bash
# Run every minute to collect metrics more frequently
* * * * * /opt/metrics/subminute_runner.sh
```

### Docker Infrastructure

#### Docker Compose Orchestration

Implemented 2 docker-compose to setup the monitoring stack, one for prometheus and node-exporter, and the other for grafana:

docker-compose (prometheus/node-exporter):

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.enable-lifecycle'
    restart: unless-stopped
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - metrics_data:/var/lib/node_exporter/textfile_collector
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.textfile.directory=/var/lib/node_exporter/textfile_collector'
    restart: unless-stopped
    networks:
      - monitoring

volumes:
  prometheus_data:
  metrics_data:

networks:
  monitoring:
    external: true
    name: monitoring
```

docker-compose (grafana):

```yaml
services:
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - ./provisioning:/etc/grafana/provisioning
      - ./dashboards:/var/lib/grafana/dashboards
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    restart: unless-stopped
    networks:
      - monitoring

volumes:
  grafana_data:

networks:
  monitoring:
    external: true
    name: monitoring
```

**Infrastructure Highlights:**

- Persistent volumes for data retention
- Proper volume mounts for textfile collector integration
- Auto-restart policies for high availability
- Grafana provisioning for automated configuration

### Grafana Configuration

#### Datasource Provisioning

Automated Prometheus datasource configuration:

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    uid: prometheus
```

The "uid" configuration is very important, it make sure to connect to that specific datasource. At first I did not have this setting, and grafana was not finding the correct datasource.

### Prometheus Configuration

Created `prometheus.yml` with custom configuration:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node_exporter:9100']
```

**Configuration Details:**

- 15-second scrape interval for real-time monitoring
- Monitors both Prometheus itself and Node Exporter
- Uses Docker service names for container communication

### Dashboard Implementation

Created comprehensive system metrics dashboard (`system-metrics-dashboard.json`) featuring:

**CPU Metrics Panel:**

- Real-time CPU usage percentage
- Time-series visualization
- Color-coded thresholds (green < 50%, yellow < 80%, red ≥ 80%)

**Memory Metrics Panel:**

- Memory usage percentage tracking
- Historical trend analysis
- Alert thresholds for high memory usage

**Disk Usage Panel:**

- Root filesystem utilization
- Storage capacity monitoring
- Critical usage warnings

**Dashboard Features:**

- Auto-refresh every 5 seconds
- Responsive design for different screen sizes
- Interactive time range selection
- Prometheus query integration

### Ansible Automation

#### Metrics Collector Role

Created comprehensive Ansible role (`metrics_collector`) for automated deployment:

- Copy scripts (system-metrics.sh and subminute_runner.sh) to the target host;
- Create log and metrics directory's to match docker-compose mounts;
- Add a cronjob to the system and run the subminute_runner.sh file;

#### Prometheus Role

Created comprehensive Ansible role (Prometheus) for automated deployment:

- Check if prometheus dir exists;
- Copy config files from prometheus;
- Create monitoring network;
- Start Prometheus and node-exporter container
- After Prometheus container is running copy the rest of the configs (This can be updated)

#### Grafana Role

Created comprehensive Ansible role (Grafana) for automated deployment:

- Create Grafana dir;
- Copy config files from Grafana;
- Copy provisioning files (dashboard and datasource)
- Create monitoring network;
- Start Grafana container;
- After Grafana container is runing copy the rest of the configs (This can be updated)

#### Monitoring Stack Deployment

Main playbook (`metrics.yml`) orchestrates the complete deployment:

```yaml
---
- name: Deploy monitoring infrastructure
  hosts: local_nodes
  become: yes
  roles:
    - metrics_collector
    - prometheus
    - grafana

- name: Verify deployment
  hosts: local_nodes
  become: yes
  tasks:
    - name: Check if metrics collection is working
      stat:
        path: /var/lib/node_exporter/textfile_collector/system_metrics.prom
      register: metrics_file

    - name: Display metrics file status
      debug:
        msg: "Metrics file exists: {{ metrics_file.stat.exists }}"
```

### Deployment and Verification

We can deploy the monitoring system by:

```bash
ansible-playbook playbooks/metrics.yml
```

#### Service Verification

All monitoring services are running correctly:

```bash
CONTAINER ID   IMAGE                       COMMAND                  STATUS
a1b2c3d4e5f6   grafana/grafana:latest     "/run.sh"               Up 2 hours
b2c3d4e5f6a1   prom/prometheus:latest     "/bin/prometheus --c…"   Up 2 hours
c3d4e5f6a1b2   prom/node-exporter:latest  "/bin/node_exporter …"   Up 2 hours
```

#### Access Points

The monitoring stack is accessible via:

- **Prometheus UI**: [http://localhost:9090](http://localhost:9090/)
- **Grafana Dashboard**: [http://localhost:3000](http://localhost:3000/) (admin/admin)
- **Node Exporter Metrics**: [http://localhost:9100](http://localhost:9100/)

### Project Structure at Milestone 2

```
OnboardingChallenge/
├── ansible-project/
│   ├── ansible.cfg
│   ├── inventory/
│   │   └── inventory.ini
│   ├── playbooks/
│   │   ├── metrics.yml          # Monitoring deployment playbook
│   │   ├── reset-metrics.yml    # Cleanup and reset playbook
│   │   └── site.yml            # Main configuration playbook
│   └── roles/
│       ├── grafana/            # Grafana configuration role
│       │   ├── files/
│       │   │   ├── docker-compose.yml
│       │   │   ├── dashboards/
│       │   │   │   └── system-metrics-dashboard.json
│       │   │   └── provisioning/
│       │   │       ├── dashboards/
│       │   │       │   ├── dashboard.yml
│       │   │       │   └── metrics-dashboard.json
│       │   │       └── datasources/
│       │   │           └── datasource.yml
│       │   └── tasks/
│       │       └── main.yml
│       ├── metrics_collector/   # Custom metrics collection role
│       │   ├── files/
│       │   │   ├── subminute_runner.sh
│       │   │   └── system-metrics.sh
│       │   └── tasks/
│       │       └── main.yml
│       ├── moon-buggy/         # Game installation role
│       │   ├── defaults/
│       │   │   └── main.yml
│       │   └── tasks/
│       │       └── main.yml
│       └── prometheus/         # Prometheus configuration role
│           ├── files/
│           │   ├── docker-compose.yml
│           │   └── prometheus.yml
│           └── tasks/
│               └── main.yml
├── infra-project/
│   ├── Monitoring/            # Additional monitoring utilities
│   │   ├── gather_metrics/
│   │   │   └── system_metrics.sh
│   │   └── grafana-prometheus_setup/
│   ├── VM-Configuration/
│   │   ├── docker-compose.yml
│   │   └── Dockerfile
└── README.md                  # This comprehensive documentation
```

---
