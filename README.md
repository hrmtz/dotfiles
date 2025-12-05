# dotfiles / VS Code + Codespaces メモ

## Codespaces × Local Terminal バグの概要

GitHub Codespaces に VS Code から接続している状態で、
`Terminal: Create New Integrated Terminal (Local)` を実行すると、本来はローカル(macOS)側の `/bin/zsh` で起動してほしいところが、
VS Code が誤って Linux 側の設定を参照してしまい、`/usr/bin/zsh` を使おうとして失敗する問題がある。

ポイント:
- ローカルウィンドウ単体では `/bin/zsh` が正しく使われる
- しかし Codespaces 接続時は、Local Terminal 起動ロジックが `profiles.osx` ではなく
  **`profiles.linux` / `defaultProfile.linux` を参照してしまう挙動** になる
- その結果、macOS 側に存在しない `/usr/bin/zsh` が選ばれ、Local Terminal 起動に失敗する

これは VS Code Remote / Codespaces 周りの挙動によるもので、ユーザー設定ミスではなく実質的なバグ・仕様欠陥に分類される。

## 回避策の方針

この挙動を逆手に取り、**Linux 側のターミナル設定を「わざと」上書きして、
Local Terminal 起動時にも `/bin/zsh` が選ばれるようにする**。

VS Code の設定として、次のような値を仕込む:

```jsonc
{
  "terminal.integrated.profiles.linux": {
    "zsh": {
      "path": "/bin/zsh",
      "args": []
    }
  },
  "terminal.integrated.defaultProfile.linux": "zsh"
}
``

これにより:
- VS Code が Local Terminal 起動時に参照する「Linux 側 default shell」が
  `/usr/bin/zsh` ではなく `/bin/zsh` になる
- 結果として、macOS 側の Local Terminal も正常に起動できるようになる
- `profiles.osx` をいじっても無視されるケースに対する、現実的なワークアラウンド

## 本リポジトリでの自動化

### 1. VS Code 設定テンプレート

`/.vscode/settings.codespaces.json` に、上記の VS Code 設定テンプレートを保存している。
内容は Linux 向けターミナル設定の上書きに限定している:

```jsonc
{
  "terminal.integrated.profiles.linux": {
    "zsh": {
      "path": "/bin/zsh",
      "args": []
    }
  },
  "terminal.integrated.defaultProfile.linux": "zsh"
}
```

### 2. Codespaces 用ブートストラップスクリプト

`scripts/codespaces-bootstrap.sh` で、Codespaces 起動時に VS Code 設定を自動適用する:

- `/.vscode/settings.json` が既に存在する場合は、その内容と `settings.codespaces.json` をマージ
  - マージには `jq` がインストールされている場合のみ使用し、
    テンプレート側の設定値が優先される (`.[0] * .[1]`)
- `settings.json` が無い、または `jq` が無い場合は、テンプレートをそのままコピー
- 複数回実行しても整合性が崩れないよう、idempotent な挙動にしている

疑似コードイメージ:

```bash
SETTINGS_DIR="/workspaces/dotfiles/.vscode"
SETTINGS_FILE="${SETTINGS_DIR}/settings.json"
TEMPLATE_FILE="${SETTINGS_DIR}/settings.codespaces.json"

mkdir -p "${SETTINGS_DIR}"

if [ -f "${TEMPLATE_FILE}" ]; then
  if command -v jq >/dev/null 2>&1 && [ -f "${SETTINGS_FILE}" ]; then
    jq -s '.[0] * .[1]' "${SETTINGS_FILE}" "${TEMPLATE_FILE}" > "${SETTINGS_FILE}.tmp"
    mv "${SETTINGS_FILE}.tmp" "${SETTINGS_FILE}"
  else
    cp "${TEMPLATE_FILE}" "${SETTINGS_FILE}"
  fi
fi
```

### 3. 使い方メモ

Codespaces 内で、このリポジトリが `/workspaces/dotfiles` にクローンされている前提で:

```bash
cd /workspaces/dotfiles
bash scripts/codespaces-bootstrap.sh
```

を実行することで、VS Code の `/.vscode/settings.json` に
上記の Linux 向けターミナル設定が自動適用される。

今後 VS Code 側でこの挙動が修正された場合は、
`settings.codespaces.json` の内容やブートストラップロジックを調整することで
影響をコントロールできるようにしてある。
