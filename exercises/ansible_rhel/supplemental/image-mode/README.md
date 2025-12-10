# Bonus - RHEL Image Mode

**Read this in other languages**:
<br>![uk](../../../../images/uk.png) [English](README.md)
<br>

## Table of Contents

- [Bonus - RHEL Image Mode (hands-on)](#bonus---rhel-image-mode-hands-on)
  - [Objective](#objective)
  - [Prerequisites](#prerequisites)
  - [Guide](#guide)
    - [Step 1 - Define image parameters](#step-1---define-image-parameters)
    - [Step 2 - Create the compose playbook](#step-2---create-the-compose-playbook)
    - [Step 3 - Run the compose from CLI](#step-3---run-the-compose-from-cli)
    - [Step 4 - (Optional) Run from Controller with a Survey](#step-4---optional-run-from-controller-with-a-survey)
    - [Step 5 - Next steps](#step-5---next-steps)

## Objective

Build a customized RHEL image (qcow2) via Image Builder API using Ansible, then discuss how to use Ansible for day-2 configuration. This demonstrates how image mode and Ansible complement each other: images provide consistent baselines, while Ansible handles environment-specific and day-2 automation.

## Guide

### Prerequisites

- An Image Builder endpoint accessible from the control host.
- This exercise runs on `localhost` (control host) using Ansible.

### Step 1 - Define image parameters

Decide on the basics:
- Distribution/architecture: RHEL 9, x86_64
- Image type: `qcow2`
- Packages to include: e.g., `httpd`, `vim`

Create a variable file `~/lab_inventory/image_vars.yml`:

```yaml
image_builder_api_url: "https://image-builder.example/api/image-builder/v1/compose"
image_name: "rhel95-lab-image"
image_distribution: "rhel-9"
image_architecture: "x86_64"
image_type: "qcow2"
image_packages:
  - httpd
  - vim
# If your lab requires auth headers, add them here
image_api_headers: {}
```

Add `localhost` to your inventory if not present:

```ini
# ~/lab_inventory/hosts
localhost ansible_connection=local
```

### Step 2 - Create the compose playbook

Create `~/lab_inventory/image_compose.yml`:

```yaml
---
- name: Compose a RHEL qcow2 image via Image Builder
  hosts: localhost
  gather_facts: false
  vars_files:
    - image_vars.yml
  vars:
    compose_body:
      distribution: "{{ image_distribution }}"
      image_requests:
        - architecture: "{{ image_architecture }}"
          image_type: "{{ image_type }}"
          repositories: []
      customizations:
        packages: "{{ image_packages | default([]) }}"

  tasks:
    - name: Start image compose
      ansible.builtin.uri:
        url: "{{ image_builder_api_url }}"
        method: POST
        headers: "{{ image_api_headers }}"
        body: "{{ compose_body | to_json }}"
        body_format: json
        status_code: [201, 200]
      register: compose_start

    - name: Extract compose id
      ansible.builtin.set_fact:
        compose_id: "{{ compose_start.json.id | default(compose_start.json.compose_id) }}"

    - name: Poll compose status until complete
      ansible.builtin.uri:
        url: "{{ image_builder_api_url }}/{{ compose_id }}"
        method: GET
        headers: "{{ image_api_headers }}"
      register: compose_status
      until: compose_status.json.status in ['success', 'failure', 'error']
      retries: 30
      delay: 10

    - name: Show compose status
      ansible.builtin.debug:
        var: compose_status.json

    - name: Fail if compose did not succeed
      ansible.builtin.fail:
        msg: "Image compose failed: {{ compose_status.json }}"
      when: compose_status.json.status != 'success'

    - name: Print download URL (if provided)
      ansible.builtin.debug:
        msg: "Download URL: {{ compose_status.json.image_href | default(compose_status.json.image_url | default('n/a')) }}"
```

Notes:
- Your environment may require different field names; the structure above matches common Image Builder API patterns. Your instructor will provide any lab-specific header or URL details.
- For cloud uploads, the request body differs. Here we keep it simple with `qcow2`.

Sample API responses (for reference):

Compose start (201 Created):

```json
{
  "id": "e2f6b9a4-6b0e-4f0a-9c9b-9b3b0a1d2c7a",
  "status": "pending"
}
```

Compose status (success):

```json
{
  "id": "e2f6b9a4-6b0e-4f0a-9c9b-9b3b0a1d2c7a",
  "status": "success",
  "image_type": "qcow2",
  "distribution": "rhel-9",
  "image_href": "https://image-builder.example/api/image/v1/artifacts/e2f6b9a4-6b0e-4f0a-9c9b-9b3b0a1d2c7a"
}
```

### Step 3 - Run the compose from CLI

From the control host:

```bash
cd ~/lab_inventory
ansible-playbook -i hosts image_compose.yml
```

Review output and record the compose ID and any download URL.

### Step 4 - (Optional) Run from Controller with a Survey

If you prefer to launch from Controller:
- Add this playbook to your Workshop Project (or a new project).
- Create a Job Template targeting `localhost` (use an Inventory with `localhost ansible_connection=local`).
- Add a Survey for:
  - image_name
  - image_packages (list)
  - image_type (default `qcow2`)
- Launch the Job Template and monitor output.

### Step 5 - Next steps

- Test the built image in your target environment (e.g., boot a VM from the qcow2).
- Layer day‑2 configuration with Ansible (e.g., apply System Roles for timesync, networking, or sudo).
- Promote the playbook into a controlled workflow (approval, environment selection, publishing steps).

---
**Navigation**
<br>
[Click here to return to the Ansible for Red Hat Enterprise Linux Workshop](../../README.md)


