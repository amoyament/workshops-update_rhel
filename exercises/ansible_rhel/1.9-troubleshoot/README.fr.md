# Exercice de l'Atelier - Débogage et Gestion des Erreurs

**Lire ceci dans d'autres langues** :
<br>![uk](../../../images/uk.png) [Anglais](README.md), ![japan](../../../images/japan.png) [Japonais](README.ja.md), ![brazil](../../../images/brazil.png) [Portugais du Brésil](README.pt-br.md), ![france](../../../images/fr.png) [Français](README.fr.md), ![Español](../../../images/col.png) [Espagnol](README.es.md).

## Table des Matières

- [Objectif](#objectif)
- [Guide](#guide)
  - [Étape 1 - Introduction au Débogage dans Ansible](#étape-1---introduction-au-débogage-dans-ansible)
  - [Étape 2 - Utilisation du Module Debug](#étape-2---utilisation-du-module-debug)
  - [Étape 3 - Gestion des Erreurs avec les Blocs](#étape-3---gestion-des-erreurs-avec-les-blocs)
  - [Étape 4 - Exécution en Mode Verbeux](#étape-4---exécution-en-mode-verbeux)
  - [Résumé](#résumé)

## Objectif

En s'appuyant sur les connaissances de base des exercices précédents, cette session se concentre sur le débogage et la gestion des erreurs dans Ansible. Vous apprendrez des techniques pour dépanner les playbooks, gérer les erreurs de manière élégante et assurer la robustesse et la fiabilité de votre automatisation.

## Guide

### Étape 1 - Introduction au Débogage dans Ansible

Le débogage est une compétence essentielle pour identifier et résoudre les problèmes au sein de vos playbooks Ansible. Ansible propose plusieurs mécanismes pour vous aider à déboguer vos scripts d'automatisation, y compris le module debug, les niveaux de verbosité augmentés et les stratégies de gestion des erreurs.

### Étape 2 - Utilisation du Module Debug

Le module `debug` est un outil simple mais puissant pour imprimer les valeurs des variables, ce qui peut être essentiel pour comprendre le flux d'exécution du playbook.

Dans cet exemple, ajoutez des tâches de débogage à votre rôle Apache dans le `tasks/main.yml` pour afficher la valeur des variables ou des messages.

#### Implémenter des Tâches de Débogage :

Insérez des tâches de débogage pour afficher les valeurs des variables ou des messages personnalisés pour le dépannage :

```yaml
- name: Display Variable Value
  ansible.builtin.debug:
    var: apache_service_name

- name: Display Custom Message
  ansible.builtin.debug:
    msg: "Le nom du service Apache est {{ apache_service_name }}"
```

### Étape 3 - Gestion des Erreurs avec les Blocs

Ansible permet de regrouper des tâches en utilisant `block` et de gérer les erreurs avec des sections `rescue`, similaires à try-catch dans la programmation traditionnelle.

Dans cet exemple, ajoutez un bloc pour gérer les erreurs potentielles lors de la configuration d'Apache dans le fichier `tasks/main.yml`.

1. Grouper les Tâches et Gérer les Erreurs :

Enveloppez les tâches qui pourraient potentiellement échouer dans un bloc et définissez une section de secours pour gérer les erreurs :

```yaml
- name: Configuration d'Apache avec Point de Défaillance Potentiel
  block:
    - name: Copier la configuration d'Apache
      ansible.builtin.copy:
        src: "{{ apache_conf_src }}"
        dest: "/etc/httpd/conf/httpd.conf"
  rescue:
    - name: Gérer la Configuration Manquante
      ansible.builtin.debug:
        msg: "Fichier de configuration Apache manquant '{{ apache_conf_src }}'. Utilisation des paramètres par défaut."
```

2. Ajoutez une variable `apache_conf_src` dans `vars/main.yml` du rôle apache.

```yaml
apache_conf_src: "files/missing_apache.conf"
```

> NOTE : Ce fichier n'existe pas explicitement pour que nous puissions déclencher la partie rescue de notre `tasks/main.yml`

### Étape 4 - Exécution en Mode Verbeux

Le mode verbeux d'Ansible (-v, -vv, -vvv ou -vvvv) augmente le détail de la sortie, fournissant plus d'informations sur l'exécution du playbook et les problèmes potentiels.

#### Exécuter le Playbook en Mode Verbeux :

Exécutez votre playbook avec l'option `-vv` pour obtenir des journaux détaillés :

```bash
ansible-navigator run deploy_apache.yml -m stdout -vv
```

```
.
.
.
```

## Résumé

Dans cet exercice, vous avez exploré des techniques de débogage essentielles et des mécanismes de gestion des erreurs dans Ansible. En intégrant des tâches de débogage, en utilisant des blocs pour la gestion des erreurs et en tirant parti du mode verbeux, vous pouvez efficacement dépanner et améliorer la fiabilité de vos playbooks Ansible.

---
**Navigation**
<br>
[Exercice Précédent](../1.8-navigator-ee/README.md) - [Prochain Exercice](../2.1-intro/README.fr.md)

[Cliquez ici pour retourner à l'atelier Ansible pour Red Hat Enterprise Linux](../README.md#section-1---command-line-ansible-exercises)

