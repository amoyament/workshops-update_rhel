# Bonus - RHEL Image Mode (overview)

**Read this in other languages**:
<br>![uk](../../../../images/uk.png) [English](README.md)
<br>

## Table of Contents

- [Bonus - RHEL Image Mode (overview)](#bonus---rhel-image-mode-overview)
  - [Objective](#objective)
  - [Guide](#guide)
    - [What is image mode?](#what-is-image-mode)
    - [How it relates to Ansible](#how-it-relates-to-ansible)
    - [Patterns to consider](#patterns-to-consider)

## Objective

Understand RHEL “image mode” at a high level and how it complements Ansible for provisioning, configuration management, and day-2 operations.

## Guide

### What is image mode?

RHEL image mode focuses on building standardized, pre-hardened system images that include the OS, packages, and baseline configuration. These images can be deployed consistently across fleets and lifecycles.

### How it relates to Ansible

Ansible remains key for:
- Injecting environment-specific configuration at deploy time
- Enforcing policy and remediating drift after deployment
- Orchestrating multi-system and application workflows

Use Ansible to parameterize what varies per environment and to manage ongoing operations.

### Patterns to consider

- Build golden images with common baselines, then apply environment-specific settings via Ansible
- Use execution environments to standardize the Ansible runtime across image build and post-deploy stages
- Combine controller workflows with image pipelines for end-to-end automation

---
**Navigation**
<br>
[Click here to return to the Ansible for Red Hat Enterprise Linux Workshop](../../README.md)


