# .zshrc — Arch Linux Polish (Gruvbox Material)

# Plugins (Arch Linux paths)
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

# Completion (Cached for fast startup)
setopt EXTENDED_GLOB
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit -C
else
  compinit
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Keybinds (Standard)
bindkey '^[[A' up-line-or-history
bindkey '^[[B' down-line-or-history
bindkey '^H' backward-kill-word
bindkey '^[[3~' delete-char

# Colors (Vivid)
export LS_COLORS="$(vivid generate gruvbox-dark)"
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Aliases (Gruvbox TUI tools)
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first'
alias cat='bat --theme="gruvbox-dark"'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias f='fd'


# FZF (Fuzzy Finder)
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh
export FZF_DEFAULT_OPTS='--color=bg+:#3c3836,bg:#282828,spinner:#8ec07c,hl:#928374,fg:#ebdbb2,header:#928374,info:#83a598,pointer:#fb4934,marker:#fb4934,fg+:#ebdbb2,prompt:#fb4934,hl+:#fb4934'
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Starship Prompt
eval "$(starship init zsh)"

# AI Tooling Path
export PATH="$HOME/.local/bin:$PATH"

# AI CLI session logging (B4) — tee transcripts to ~/.local/share/ai-logs.
# `command` bypasses these wrappers; AI_LOG=0 bypasses logging too.
claude() { ai-log claude "$@"; }
gemini() { ai-log gemini "$@"; }

# E1: per-project AI context — export $AI_PROJECT_CONTEXT on dir change.
# claude/gemini already auto-load CLAUDE.md/GEMINI.md; this is discovery
# + an env handle (`ai-ctx init` scaffolds AGENTS.md on demand).
autoload -Uz add-zsh-hook
_ai_ctx_chpwd() {
  local c; c=$(ai-ctx path 2>/dev/null)
  if [[ -n $c ]]; then export AI_PROJECT_CONTEXT="$c"; else unset AI_PROJECT_CONTEXT; fi
}
add-zsh-hook chpwd _ai_ctx_chpwd
_ai_ctx_chpwd


