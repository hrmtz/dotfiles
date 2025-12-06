# dotfiles

個人用の dotfiles 一式。macOS / Linux / GitHub Codespaces を想定しており、
`install.sh` を実行することでホームディレクトリに設定をリンクして適用する。

---

## ディレクトリ・ファイル構成

主要な構成だけを抜粋:

- `install.sh`  
  共通のインストールエントリーポイント

- `zsh/`
  - `zshrc` … 共通の `~/.zshrc` エントリーポイント
  - `zprofile` … 共通の `~/.zprofile`
  - `zshrc.common` / `zshrc.macos` / `zshrc.codespaces` など … 環境別の zsh 設定をここで分岐

- `.p10k.zsh`  
  デフォルトの Powerlevel10k 設定

- `.p10k.codespaces.zsh`  
  Codespaces 向けの Powerlevel10k 設定（Ubuntu オレンジ系ラインなど）

- `mac-p10k.zsh.txt`  
  mac 用 p10k 設定のバックアップ/メモ

- `git/`
  - `gitconfig` → `~/.gitconfig`
  - `gitignore` → `~/.gitignore`

- `vim/`
  - `vimrc` → `~/.vimrc`
  - `vim/` → `~/.vim/`

- `scripts/`
  - `macos-bootstrap.sh` … macOS 用追加セットアップ
  - `codespaces-bootstrap.sh` … Codespaces 用追加セットアップ (VS Code 設定・CLI ツールなど)
  - `apply-devcontainer.sh` … カレントプロジェクトに devcontainer テンプレートをコピーするヘルパー

- `.vscode/`
  - `settings.codespaces.json` … Codespaces 用 VS Code 設定テンプレート  
    （Local Terminal が `/bin/zsh` で起動するようにするワークアラウンドなど）

---

## インストールの流れ

どの環境でも基本は同じで、リポジトリをクローンして `install.sh` を叩くだけ。

```bash
git clone git@github.com:hrmtz/dotfiles.git ~/.dotfiles   # もしくは /workspaces/dotfiles など
cd ~/.dotfiles
bash install.sh
```

### `install.sh` がやっていること（概要）

1. 自分自身のパスを `DOTFILES_DIR` として取得
2. `~/.dotfiles` が無ければ `DOTFILES_DIR` への symlink を貼る
3. `link()` 関数で、既存ファイルを壊さないように `ln -s` を張る
   - 既存ファイルがある場合は、`DOTFILES_FORCE=1` のときだけ上書き
4. `~/.zshrc`, `~/.zprofile`, `~/.p10k.zsh`, `~/.zsh` ディレクトリなどをリンク
5. Git / Vim の設定ファイルをリンク
6. zsh があれば、ログインシェルを zsh に変更（失敗しても警告だけ出して続行）
7. プラットフォームを検出して、環境別のブートストラップスクリプトを呼び出す

### プラットフォーム判定

`detect_platform()` で次のように判定:

- `CODESPACES` 環境変数があれば `codespaces`
- `OSTYPE` もしくは `uname` が `Darwin` なら `macos`
- それ以外は `linux`

---

## 環境別の挙動

### 共通 (全環境)

- `zsh/zshrc` → `~/.zshrc` としてリンク
- `zsh/zprofile` → `~/.zprofile`
- `.p10k.zsh` → `~/.p10k.zsh`（後で Codespaces では上書きされる）
- `zsh/` → `~/.zsh/`
- Git, Vim の設定をホームにリンク

### macOS

- `detect_platform` により `platform=macos` となる
- `scripts/macos-bootstrap.sh` が存在し、かつ実行権限があれば実行
  - Homebrew など macOS 特有のセットアップはここに追記していく想定
- Powerlevel10k はデフォルトで `.p10k.zsh` を使用
  - 必要に応じて `mac-p10k.zsh.txt` を参考に変更

### Linux (ローカル Linux)

- 現状は特別な追加スクリプトは無く、共通設定のみ適用
- 必要になれば `scripts/linux-bootstrap.sh` のようなフックを追加してもよい

### GitHub Codespaces

1. `detect_platform` により `platform=codespaces`
2. `install.sh` の中で Codespaces 向けに次を実行:
   - `.p10k.codespaces.zsh` があれば、`~/.p10k.zsh` をそれに差し替える  
     → Codespaces では専用の p10k テーマが使われる
   - `scripts/codespaces-bootstrap.sh` を実行

#### `scripts/codespaces-bootstrap.sh` の役割

- `apt` があれば、`fzf`, `fd-find`, `ripgrep`, `lsd` など CLI ツールをインストール
- VS Code 向け設定を自動適用:
  - `.vscode/settings.codespaces.json` をテンプレートとして扱う
  - `.vscode/settings.json` が既にある場合は、`jq` があればマージする  
    (`jq -s '.[0] * .[1]'` で「既存設定 * テンプレ」の形でマージし、テンプレ側が優先)
  - `jq` が無い or `settings.json` が無い場合はテンプレをそのままコピー
  - 複数回実行しても壊れない idempotent な処理

#### devcontainer テンプレートと zsh デフォルト化

Codespaces で「毎回 bash ではなく zsh で統合ターミナルを開きたい」場合、
各プロジェクトに devcontainer 設定を 1 度だけ置いておくと、その後は自動で zsh が使われる。

- dotfiles 側テンプレート: `~/.dotfiles/.devcontainer/`
  - `devcontainer.json`
    - VS Code の `terminal.integrated.defaultProfile.linux` を `zsh` に設定
    - `terminal.integrated.profiles.linux.zsh.path` を `/bin/zsh` に固定
  - `postCreate.zsh-setup.sh`
    - コンテナ内で zsh が無ければインストール
    - `getent passwd "$USER"` からユーザー名と現在のシェルを取得し、`chsh` でログインシェルを zsh に変更
    - 失敗しても非致命 (警告を出して続行)

このテンプレートを実際のプロジェクトに適用するには、プロジェクトルートで次のどちらかを行う。

1. 手動でコピーする場合:

   ```bash
   cd /workspaces/your-project
   mkdir -p .devcontainer
   cp ~/.dotfiles/.devcontainer/devcontainer.json .devcontainer/devcontainer.json
   cp ~/.dotfiles/.devcontainer/postCreate.zsh-setup.sh .devcontainer/postCreate.zsh-setup.sh
   chmod +x .devcontainer/postCreate.zsh-setup.sh
   ```

2. ヘルパースクリプトを使う場合 (`scripts/apply-devcontainer.sh`):

   ```bash
   cd /workspaces/your-project
   ~/.dotfiles/scripts/apply-devcontainer.sh
   ```

その後、VS Code の「Reopen in Container」または「Rebuild Container」を実行すると、
そのプロジェクトでは:

- コンテナユーザーのログインシェルが zsh に変更される
- VS Code 統合ターミナルも `/bin/zsh` で起動する

という状態になり、同じリポジトリの Codespaces を作り直しても毎回自動で zsh が使われる。

---

## VS Code × Codespaces × Local Terminal のバグと回避策

### 問題の概要

Codespaces 接続中に VS Code のコマンドパレットから  
`Terminal: Create New Integrated Terminal (Local)` を実行すると、本来はローカル(macOS)側の
`/bin/zsh` で起動してほしいところが、VS Code が誤って Linux 側の設定を参照し、  
存在しない `/usr/bin/zsh` を使おうとして失敗する問題がある。

ポイント:

- ローカルウィンドウ単体では `/bin/zsh` が正しく使われる
- Codespaces 接続時は、Local Terminal 起動ロジックが `profiles.osx` ではなく  
  **`terminal.integrated.profiles.linux` / `terminal.integrated.defaultProfile.linux` を参照している挙動** になる
- macOS 側に `/usr/bin/zsh` は無いため、Local Terminal が起動できない

これは VS Code Remote / Codespaces 周りの挙動によるもので、ユーザー設定ミスではなく  
実質的なバグ・仕様欠陥に近い。

### 回避策の方針

この挙動を逆手に取り、**Linux 側のターミナル設定を「わざと」上書きして、  
Local Terminal 起動時にも `/bin/zsh` が選ばれるようにする**。

テンプレートとして、`.vscode/settings.codespaces.json` に次の設定を持たせている:

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

これにより:

- VS Code が Local Terminal 起動時に参照する「Linux 側 default shell」が  
  `/usr/bin/zsh` ではなく `/bin/zsh` になる
- 結果として、macOS 側の Local Terminal も正常に起動できるようになる
- `profiles.osx` をいじっても無視されるケースに対する、現実的なワークアラウンド

### Codespaces での適用方法

Codespaces 内で、このリポジトリが `/workspaces/dotfiles` にある前提で:

```bash
cd /workspaces/dotfiles
bash scripts/codespaces-bootstrap.sh
```

を実行すれば、上記設定が VS Code の `.vscode/settings.json` に自動適用される。

今後 VS Code 側で挙動が修正された場合は、`settings.codespaces.json` の内容や  
ブートストラップロジックを調整することで影響をコントロールできるようにしている。
