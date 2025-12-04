# Bonus Exercise - RHEL System Roles (optional)

**Read this in other languages**:
<br>![uk](../../../images/uk.png) [English](README.md)
<br>

## Table of Contents

- [Exercise 1.10 - RHEL System Roles](#exercise-110---rhel-system-roles)
  - [Objective](#objective)
  - [Guide](#guide)
    - [Step 1 - Overview of RHEL System Roles](#step-1---overview-of-rhel-system-roles)
    - [Step 2 - Apply a simple system role](#step-2---apply-a-simple-system-role)
    - [Step 3 - Verify the result](#step-3---verify-the-result)

## Objective

Get hands-on with Red Hat Enterprise Linux (RHEL) System Roles to automate common OS configuration tasks using production-ready roles delivered as Ansible collections.

You will apply a simple role to a host and verify the change. This is an optional exercise that can be skipped if you are short on time.

> Note: RHEL 9.5 includes continued updates to system roles. Explore additional roles (e.g., time synchronization, storage, network, and sudo) based on your use case.

## Guide

### Step 1 - Overview of RHEL System Roles

RHEL System Roles are provided as Ansible content to configure and manage RHEL at scale in a consistent way.

Common role categories include:
- Time synchronization
- Networking
- Storage
- Kernel settings
- Sudo and users

### Step 2 - Apply a simple system role

We’ll demonstrate the time synchronization role to ensure NTP is configured.

Create a playbook `timesync.yml`:

```yaml
---
- name: Configure time synchronization with RHEL System Roles
  hosts: node1
  become: true
  roles:
    - role: rhel.system_roles.timesync
      vars:
        timesync_ntp_servers:
          - hostname: pool.ntp.org
            iburst: yes
```

Run the playbook:

```bash
ansible-playbook timesync.yml -i ~/lab_inventory/hosts
```

> If the `rhel.system_roles` collection is not present in your environment, your instructor or backend images will provide it. No manual install is required for this lab.

### Step 3 - Verify the result

Check that the timesync service is active:

```bash
ansible -i ~/lab_inventory/hosts node1 -m command -a "timedatectl status"
```

You should see NTP service active and synchronized.

---
**Navigation**
<br>
[Previous Exercise](../1.9-troubleshoot) - [Next Exercise](../2.1-intro)

[Click here to return to the Ansible for Red Hat Enterprise Linux Workshop](../README.md)


