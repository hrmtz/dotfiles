
##### Powerlevel10k Instant Prompt #####
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

##### zinit（プラグインマネージャ） #####
# 初回だけ clone。既にあれば何もしない。
if [[ ! -d ${HOME}/.zinit/bin ]]; then
  mkdir -p "${HOME}/.zinit"
  git clone https://github.com/zdharma-continuum/zinit.git "${HOME}/.zinit/bin"
fi

# zinit 読み込み
source "${HOME}/.zinit/bin/zinit.zsh"

##### Powerlevel10k 本体 #####
# instant prompt の静音モード（元設定を維持）
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# p10k を shallow clone で取得
zinit ice depth=1
zinit light romkatv/powerlevel10k

# p10k の設定ファイル（なければ `p10k configure` で作る）
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

##### 補完用プラグイン（oh-my-zsh の代わり） #####
# oh-my-zsh の plugins=(zsh-completions) を zinit で置き換え
zinit light zsh-users/zsh-completions

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
# Codespaces で zcompdump 衝突を避ける
ZSH_COMPDUMP=$HOME/.zcompdump-$HOST-$ZSH_VERSION
compinit -d $ZSH_COMPDUMP

# あなたの求めた曖昧補完（cd D/D/ → Dropbox/Documents）
zstyle ':completion:*' matcher-list \
  'm:{a-z}={A-Z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''

# docker 補完
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

##### キーバインド #####
bindkey -e
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward

##### alias（軽いものだけ移植） #####
if command -v lsd >/dev/null 2>&1; then
  alias ls="lsd"
  alias la="lsd --long --all --group"
fi

if command -v bat >/dev/null 2>&1; then
  alias cat="bat"
fi
