starship init fish | source
zoxide init --cmd cd fish | source

# Paths
set -x STARSHIP_CONFIG ../starship/starship.toml

# pnpm
set -gx PNPM_HOME "/Users/sornchaisomsakul/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
