
---
## Milestone 1 - Ansible Setup

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

