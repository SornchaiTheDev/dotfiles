starship init fish | source
zoxide init --cmd cd fish | source

# Paths
set -x STARSHIP_CONFIG ~/.config/starship/starship.toml

# pnpm
set -gx PNPM_HOME "/Users/sornchaisomsakul/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

function ls
  command eza --icons $argv
end

function ta
  command tmux a
end

# Load pyenv automatically by adding
# the following to ~/.config/fish/config.fish:

status --is-interactive; and . (pyenv init -|psub)

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
