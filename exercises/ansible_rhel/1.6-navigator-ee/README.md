# Exercise - Ansible Navigator and Execution Environments (basics)

**Read this in other languages**:
<br>![uk](../../../images/uk.png) [English](README.md)
<br>

## Table of Contents

- [Exercise - Ansible Navigator and Execution Environments (basics)](#exercise---ansible-navigator-and-execution-environments-basics)
  - [Objective](#objective)
  - [Guide](#guide)
    - [Step 1 - What is an Execution Environment?](#step-1---what-is-an-execution-environment)
    - [Step 2 - Running a playbook with ansible-navigator](#step-2---running-a-playbook-with-ansible-navigator)
    - [Step 3 - Explore docs and collections](#step-3---explore-docs-and-collections)
    - [Step 4 - Compare to ansible-playbook](#step-4---compare-to-ansible-playbook)

## Objective

In this exercise you’ll learn the basics of Ansible Navigator and Execution Environments (EEs). You will:

- Understand how EEs package python dependencies, ansible-core, and collections
- Run an existing playbook using `ansible-navigator`
- Browse module docs from the CLI
- Contrast with the `ansible-playbook` command used earlier

> We intentionally introduce Navigator after the command-line basics to reduce onboarding friction for new users.

## Guide

This exercise builds on the playbooks you created earlier in the workshop.

### Step 1 - What is an Execution Environment?

An Execution Environment is a container image that includes:
- ansible-core
- Python runtimes and libraries
- Ansible collections and dependencies

Using an EE helps ensure consistent results across developer desktops and automation controller.

> Note: Your lab environment provides a default EE. Backend image pull and updates are handled for you.

### Step 2 - Running a playbook with ansible-navigator

Change to your working directory:

```bash
cd ~/lab_inventory
```

Run the playbook you created earlier using Navigator in stdout mode:

```bash
ansible-navigator run system_setup.yml -m stdout
```

Observe that execution uses the default EE configured for your environment.

### Step 3 - Explore docs and collections

Use Navigator to view documentation for commonly used modules:

```bash
ansible-navigator doc ansible.builtin.package -m stdout
ansible-navigator doc ansible.builtin.user -m stdout
```

List available collections inside the EE:

```bash
ansible-navigator collections -m stdout
```

### Step 4 - Compare to ansible-playbook

Earlier, you ran the same playbooks using `ansible-playbook`. Navigator complements that workflow by:
- Standardizing the runtime via EEs
- Offering helpful TUI and stdout experiences
- Providing built-in docs exploration

Use whichever is appropriate for your team’s workflow. In automation controller, jobs run with EEs by default.

---
**Navigation**
<br>
[Previous Exercise](../1.5-collection) - [Next Exercise](../1.7-troubleshoot)

[Click here to return to the Ansible for Red Hat Enterprise Linux Workshop](../README.md)


