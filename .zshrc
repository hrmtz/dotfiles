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

# zcompdump を Codespaces でも壊れにくくする
if [[ ! -d $HOME/.zcompdump.d ]]; then
  mkdir -p $HOME/.zcompdump.d
fi
ZSH_COMPDUMP=$HOME/.zcompdump.d/.zcompdump-$HOST-$ZSH_VERSION
compinit -d $ZSH_COMPDUMP

# 補完の曖昧マッチ
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

##### プロンプト #####
PROMPT='%n@%m:%~ %# '
