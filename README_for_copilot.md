# Copilot Handover for This Repo

> このドキュメントは、GitHub Copilot / Copilot Chat / Copilot Edits に対する「申し送り」です。  
> プロジェクトの前提・やってほしいこと・やってほしくないことをここに書きます。

---

## 0. How to interact with the user

- **Language**: Reply in **Japanese** by default.
- **Tone**:  
  - 過剰に優しくする必要はない。  
  - 技術的にはストレートに指摘してよいが、情報は正確に。
- **Assumptions about the user**:
  - Git / GitHub / Codespaces / devcontainer は一通り使える前提。
  - Python, CLI, Docker, VSCode の基本操作は理解している前提。
  - ただし「面倒な反復作業」は極力 AI に押し付けたいと思っている。

---

## 1. Project overview (fill this for the current repo)

> ※ ここはリポジトリごとに手で埋める。

- **Project name**: `dotfiles`
- **Goal**:  
  - ユーザーの開発環境を自動セットアップする dotfiles リポジトリ。
- **Main use cases**:
  - ローカル macOS / Linux 環境でのセットアップ。
  - GitHub Codespaces 環境でのセットアップ。

---

## 2. Tech stack & environment

- **Languages**:  
  - Shell script (bash, zsh)
- **Frameworks / libs**:  
  - N/A
- **Runtime environment**:
  - macOS, Linux, GitHub Codespaces

### Shell / Terminal 設定に関する前提（重要）

- ユーザーは **zsh を標準シェルとして使いたい**。
- ローカルと Codespaces でパスがズレる問題があった：

  #### 過去に起きた問題

  - Codespaces 接続時、VSCode の統合ターミナルが **`/usr/bin/zsh` を指していてうまく動かない** ケースがあった。
  - ローカルでは `/bin/zsh` を使っており、Codespaces ではそれが **上書きされてしまう** 挙動だった。

  #### 解決方法（既知の良い状態）

  - VSCode の `settings.json` で、Linux プロファイルを明示的に `/bin/zsh` に固定する：

    ```jsonc
    "terminal.integrated.profiles.linux": {
      "zsh": {
        "path": "/bin/zsh",
        "args": []
      }
    },
    "terminal.integrated.defaultProfile.linux": "zsh"
    ```

  - devcontainer でユーザーのログインシェルを zsh にしたい場合は、例えば以下のようなスクリプトを使う（必要なときだけ提案すること）:

    ```bash
    #!/usr/bin/env bash
    set -euo pipefail

    if ! command -v zsh >/dev/null 2>&1; then
      sudo apt-get update
      sudo apt-get install -y zsh
    fi

    if [ "$(getent passwd vscode | cut -d: -f7)" != "$(command -v zsh)" ]; then
      sudo chsh -s "$(command -v zsh)" vscode || true
    fi
    ```

- **Copilot への指示**:  
  - シェル関連をいじる話になったら、**まず `/bin/zsh` を使う前提で考えること**。  
  - `/usr/bin/zsh` を安易に推奨しない。  
  - 既存設定を壊さないため、`settings.json` の変更は**明示的にユーザーに確認されたときだけ**提案する。

---

## 3. Repository map

- **Directory structure**:

```
/README_for_copilot.md
/scripts/                # 環境別セットアップスクリプト
  macos-bootstrap.sh     # macOS 向けセットアップ
  codespaces-bootstrap.sh# Codespaces 向けセットアップ
/zsh/                    # zsh 関連設定 
  zshrc                  # ~/.zshrc へのリンク元
  zprofile               # ~/.zprofile へのリンク元
  .p10k.zsh              # Powerlevel10k 設定（共通 ）
  .p10k.codespaces.zsh   # Powerlevel10k 設定（ Codespaces 専用）
  mac-p10k.zsh.txt       # Powerlevel10k 設定（ macOS 専用、参考用）
/.vscode/                # VSCode 設定
  settings.codespaces.json # Codespaces 向け設定テンプレート
/install.sh              # インストールスクリプト
```

> Copilot への期待:  
> - 上記ディレクトリ構成を前提に、依存関係を追って回答すること。  
> - 新しい機能を追加するときは、どのレイヤーに置くべきかをまず提案すること。

---

## 4. What Copilot SHOULD do

- **小さな変更を素早く出す**:
  - 既存の関数に 1–5 行程度のロジック追加
  - バグ修正・型ヒント・docstring の追加
  - 既存スタイルを崩さない範囲のリファクタリング

- **構造を踏まえた提案をする**:
  - 新しいスクリプトや設定ファイルを追加するときは、  
    既存の `scripts/` や `zsh/` の構造を踏まえた上で、  
    適切な場所に追加する案を出す。

- **設定まわりの操作**:
  - `.devcontainer/`, `.vscode/`, `settings.json` の変更は、**目的を明示したうえで**提案する。  
  - ユーザーが「自動化したい」と言ったときだけ、`postCreateCommand` や `postAttachCommand` への組み込みを提案する。

---

## 5. What Copilot SHOULD NOT do (without explicit request)

- プロジェクトの根本設計（ディレクトリ構造・命名体系・主要な I/F）を勝手に変えない。
- 大量のファイルを一度に書き換えるリファクタリングを、ユーザーの確認なしでやろうとしない。
- devcontainer や Docker の設定を、大幅に変更しない（壊れやすい）。

---

## 6. Typical tasks you (Copilot) will be asked

1. **「この機能を追加したい」系**
   - 手順:
     1. 実装済みの類似機能をリポジトリから探す。
     2. 既存パターンを真似する形で、新しい関数・スキーマ・テンプレを提案。
     3. 変更ファイルと影響範囲を明示。

2. **「設定まわりを直したい」系（例: シェル、ターミナル、devcontainer）**
   - 手順:
     1. 既存の `.devcontainer/devcontainer.json`, `.vscode/settings.json` を読む。
     2. 最小限の差分で済む案を出す（特に zsh の話では `/bin/zsh` を前提とする）。
     3. 実際に貼り付ける JSON / bash スニペットを提示。

3. **「今起きているエラーの原因を特定してほしい」系**
   - ログやスタックトレースを元に、  
     - どのファイル・どの関数・どの設定が原因か  
     - どのように修正すべきか  
     を具体的に指示する。

---

## 7. Notes about learning / code quality

- このリポジトリは、  
  **「とりあえず動けばいい」ではなく「あとで読んでも理解できるコード」にする** ことを目的にしている。
- Copilot は、次のような点に注意して提案すること：
  - 関数・変数名は、用途が一目でわかるようにする。
  - コメントは「なぜそうしているか」を書く（「何をしているか」だけは避ける）。
  - テストがあるファイルには、できるだけテストも追加する案を出す。

---

## 8. If you are unsure

- 分からないことは無理に断定しない。  
- 「ここまでは確実だが、◯◯の部分はユーザーに確認が必要」と明記して回答する。  
- 推測で大きな変更案を勝手に出さず、まずは「こういう方針でよいか？」と確認のプロンプトを提案する。
