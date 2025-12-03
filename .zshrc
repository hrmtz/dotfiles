##### 基本オプション #####
setopt AUTO_CD
setopt AUTO_MENU
setopt AUTO_LIST
setopt MENU_COMPLETE
setopt CORRECT

##### ヒストリ #####
HISTSIZE=5000
SAVEHIST=5000
HISTFILE=$HOME/.zsh_history

setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY

##### 補完システム #####
autoload -Uz compinit

# zcompdump を分離（Codespaces でも壊れにくくする）
if [[ ! -d $HOME/.zcompdump.d ]]; then
  mkdir -p $HOME/.zcompdump.d
fi
ZSH_COMPDUMP=$HOME/.zcompdump.d/.zcompdump-$HOST-$ZSH_VERSION
compinit -d $ZSH_COMPDUMP

# ここから「mac の .zshrc から移植する部分」

# ~/.zsh/completion を補完パスに追加
if [ -d ~/.zsh/completion ]; then
  fpath=(~/.zsh/completion $fpath)
fi

# docker 補完のオプション
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

# 補完で小文字でも大文字にマッチ（＋曖昧マッチ強化）
zstyle ':completion:*' matcher-list \
  'm:{a-z}={A-Z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''

##### キーバインド #####
bindkey -e

bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward

##### alias（mac 設定から移植） #####
# ls の代替 lsd（存在する場合のみ）
if command -v lsd >/dev/null 2>&1; then
  alias ls="lsd"
  alias la="lsd --long --all --group"
fi

# cat の代替 bat（なければ単に cat のまま）
if command -v bat >/dev/null 2>&1; then
  alias cat="bat"
fi

##### プロンプト #####
PROMPT='%n@%m:%~ %# '
