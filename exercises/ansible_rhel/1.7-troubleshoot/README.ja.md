# ワークショップ演習 - デバッグとエラーハンドリング

**他の言語で読む** :
<br>![uk](../../../images/uk.png) [英語](README.md), ![japan](../../../images/japan.png) [日本語](README.ja.md), ![brazil](../../../images/brazil.png) [ブラジルのポルトガル語](README.pt-br.md), ![france](../../../images/fr.png) [フランス語](README.fr.md), ![Español](../../../images/col.png) [スペイン語](README.es.md).

## 目次

- [目的](#目的)
- [ガイド](#ガイド)
  - [ステップ 1 - Ansibleでのデバッグ入門](#ステップ-1---Ansibleでのデバッグ入門)
  - [ステップ 2 - デバッグモジュールの利用](#ステップ-2---デバッグモジュールの利用)
  - [ステップ 3 - ブロックによるエラーハンドリング](#ステップ-3---ブロックによるエラーハンドリング)
  - [ステップ 4 - 詳細モードでの実行](#ステップ-4---詳細モードでの実行)
  - [まとめ](#まとめ)

## 目的

これまでの演習で得た基礎知識を基に、このセッションではAnsible内でのデバッグとエラーハンドリングに焦点を当てます。プレイブックのトラブルシューティング、エラーの上手な管理、堅牢で信頼性の高い自動化を実現するためのテクニックを学びます。

## ガイド

### ステップ 1 - Ansibleでのデバッグ入門

デバッグは、Ansibleプレイブック内の問題を特定し解決するための重要なスキルです。Ansibleはデバッグモジュール、詳細度レベルの増加、エラーハンドリング戦略など、自動化スクリプトのデバッグを支援するいくつかのメカニズムを提供します。

### ステップ 2 - デバッグモジュールの利用

`debug` モジュールは、変数の値を出力するためのシンプルだが強力なツールであり、プレイブックの実行フローを理解する上で重要です。

この例では、変数の値またはメッセージを出力するデバッグタスクを `tasks/main.yml` のApacheロールに追加します。

#### デバッグタスクの実装 :

変数の値やカスタムメッセージを表示するデバッグタスクを挿入します :

```yaml
- name: Display Variable Value
  ansible.builtin.debug:
    var: apache_service_name

- name: Display Custom Message
  ansible.builtin.debug:
    msg: "Apacheサービス名は {{ apache_service_name }} です"
```

### ステップ 3 - ブロックによるエラーハンドリング

Ansibleでは `block` を使用してタスクをグループ化し、`rescue` セクションでエラーを処理できます。これは伝統的なプログラミングのtry-catchに似ています。

この例では、`tasks/main.yml` ファイル内でApacheの設定中に発生する可能性のあるエラーを処理するためのブロックを追加します。

1. タスクのグループ化とエラーの処理 :

失敗する可能性のあるタスクをブロックでラップし、エラーを処理するためのレスキューセクションを定義します :

```yaml
- name: Apache Configuration with Potential Failure Point
  block:
    - name: Copy Apache configuration
      ansible.builtin.copy:
        src: "{{ apache_conf_src }}"
        dest: "/etc/httpd/conf/httpd.conf"
  rescue:
    - name: Handle Missing Configuration
      ansible.builtin.debug:
        msg: "'{{ apache_conf_src }}' のApache設定ファイルが見つかりません。デフォルト設定を使用します。"
```

2. apacheロールの `vars/main.yml` 内に `apache_conf_src` 変数を追加します。

```yaml
apache_conf_src: "files/missing_apache.conf"
```

> 注: このファイルは意図的に存在しないため、`tasks/main.yml` のレスキュー部分をトリガーすることができます。

### ステップ 4 - 詳細モードでの実行

Ansibleの詳細モード(-v, -vv, -vvv, -vvvv)は出力の詳細度を高め、プレイブックの実行と潜在的な問題に関するより多くの洞察を提供します。

#### 詳細モードでプレイブックを実行 :

詳細なログを取得するために `-vv` オプションを使用してプレイブックを実行します :

```bash
ansible-navigator run deploy_apache.yml -m stdout -vv
```

```
...
```

## まとめ

この演習では、Ansibleでの重要なデバッグ技術とエラーハンドリングメカニズムを探求しました。

---
**ナビゲーション**
<br>
[前の演習](../1.8-navigator-ee/README.md) - [次の演習](../2.1-intro/README.ja.md)

[Red Hat Enterprise LinuxのためのAnsibleワークショップに戻る](../README.md#section-1---command-line-ansible-exercises)

