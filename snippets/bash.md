
# search history with ↑

```bash
cat > ~/.inputrc <<EOF
# Respect default shortcuts.
$include /etc/inputrc

## arrow up
"\e[A":history-search-backward
## arrow down
"\e[B":history-search-forward
EOF
```
