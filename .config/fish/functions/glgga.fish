function glgga --wraps='git log --all --decorate --oneline --graph' --description 'alias glgga=git log --all --decorate --oneline --graph'
  git log --all --decorate --oneline --graph $argv
        
end
