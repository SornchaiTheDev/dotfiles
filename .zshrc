eval "$(zoxide init zsh --cmd cd)"

# Alias
alias ls=eza
alias l="eza -l"
alias vim=nvim
alias t=tmux
alias ta="tmux a"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
