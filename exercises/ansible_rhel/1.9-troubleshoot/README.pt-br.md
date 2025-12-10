# Exercício do Workshop - Depuração e Tratamento de Erros

**Leia isso em outros idiomas**:
<br>![uk](../../../images/uk.png) [Inglês](README.md), ![japan](../../../images/japan.png) [Japonês](README.ja.md), ![brazil](../../../images/brazil.png) [Português do Brasil](README.pt-br.md), ![france](../../../images/fr.png) [Francês](README.fr.md), ![Español](../../../images/col.png) [Espanhol](README.es.md).

## Índice

- [Objetivo](#objetivo)
- [Guia](#guia)
  - [Etapa 1 - Introdução à Depuração no Ansible](#etapa-1---introdução-à-depuração-no-ansible)
  - [Etapa 2 - Utilizando o Módulo de Depuração](#etapa-2---utilizando-o-módulo-de-depuração)
  - [Etapa 3 - Tratamento de Erros com Blocos](#etapa-3---tratamento-de-erros-com-blocos)
  - [Etapa 4 - Executando em Modo Verbose](#etapa-4---executando-em-modo-verbose)
  - [Resumo](#resumo)

## Objetivo

Baseando-se no conhecimento fundamental dos exercícios anteriores, esta sessão foca na depuração e tratamento de erros dentro do Ansible. Você aprenderá técnicas para solucionar problemas em playbooks, gerenciar erros de forma elegante e garantir que sua automação seja robusta e confiável.

## Guia

### Etapa 1 - Introdução à Depuração no Ansible

A depuração é uma habilidade crucial para identificar e resolver problemas dentro dos seus playbooks do Ansible. O Ansible oferece vários mecanismos para ajudá-lo a depurar seus scripts de automação, incluindo o módulo de depuração, níveis de verbosidade aumentados e estratégias de tratamento de erros.

### Etapa 2 - Utilizando o Módulo de Depuração

O módulo `debug` é uma ferramenta simples, porém poderosa, para imprimir os valores das variáveis, o que pode ser fundamental para entender o fluxo de execução do playbook.

Neste exemplo, adicione tarefas de depuração ao seu papel do Apache no `tasks/main.yml` para exibir o valor das variáveis ou mensagens.

#### Implementar Tarefas de Depuração:

Insira tarefas de depuração para exibir os valores das variáveis ou mensagens personalizadas para solução de problemas:

```yaml
- name: Display Variable Value
  ansible.builtin.debug:
    var: apache_service_name

- name: Display Custom Message
  ansible.builtin.debug:
    msg: "O nome do serviço Apache é {{ apache_service_name }}"
```

### Etapa 3 - Tratamento de Erros com Blocos

O Ansible permite agrupar tarefas usando `block` e tratar erros com seções `rescue`, semelhante ao try-catch na programação tradicional.

Neste exemplo, adicione um bloco para tratar erros potenciais durante a configuração do Apache no arquivo `tasks/main.yml`.

1. Agrupar Tarefas e Tratar Erros:

Envolver as tarefas que podem falhar potencialmente em um bloco e definir uma seção de resgate para tratar os erros:

```yaml
- name: Configuração do Apache com Ponto de Falha Potencial
  block:
    - name: Copiar configuração do Apache
      ansible.builtin.copy:
        src: "{{ apache_conf_src }}"
        dest: "/etc/httpd/conf/httpd.conf"
  rescue:
    - name: Tratar Configuração Ausente
      ansible.builtin.debug:
        msg: "Arquivo de configuração do Apache '{{ apache_conf_src }}' ausente. Usando configurações padrão."
```

2. Adicione uma variável `apache_conf_src` dentro de `vars/main.yml` do papel apache.

```yaml
apache_conf_src: "files/missing_apache.conf"
```

> NOTA: Este arquivo explicitamente não existe para que possamos acionar a parte do resgate em nosso `tasks/main.yml`

### Etapa 4 - Executando em Modo Verbose

O modo verbose do Ansible (-v, -vv, -vvv ou -vvvv) aumenta o detalhe da saída, fornecendo mais insights sobre a execução do playbook e possíveis problemas.

#### Executar o Playbook em Modo Verbose:

Execute seu playbook com a opção `-vv` para obter logs detalhados:

```bash
ansible-navigator run deploy_apache.yml -m stdout -vv
```

```
...
```

## Resumo

Neste exercício, você explorou técnicas essenciais de depuração e mecanismos de tratamento de erros no Ansible.

---
**Navegação**
<br>
[Exercício Anterior](../1.8-navigator-ee/README.md) - [Próximo Exercício](../2.1-intro/README.pt-br.md)

[Clique aqui para retornar ao Workshop de Ansible para Red Hat Enterprise Linux](../README.md#section-1---command-line-ansible-exercises)

