# Desktop config (niri + quickshell)

Tracked: `quickshell/` (bar + Wi-Fi popup) and `niri/`.
Everything else in ~/.config is ignored on purpose (see .gitignore).

## Rollback
    git log --oneline                  # find the commit
    git diff <commit> -- quickshell    # see what changed
    git checkout <commit> -- quickshell   # restore files from that commit
    git restore .                      # throw away uncommitted edits

Quickshell hot-reloads on file changes. After changing niri files: `niri msg action load-config-file`.

Restart the bar: Mod+Shift+B, or `pkill -x qs; setsid -f qs`.
