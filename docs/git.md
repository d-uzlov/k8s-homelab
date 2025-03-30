
# Setup

```bash
git config --global user.email "example@example"
git config --global user.name "FirstName LastName"
```

# Show current config

```bash
git config --list
git config --list --show-origin
```

# Checkout a branch from a pull request

```bash
ID=1440
branch_name=pull-request-branch-name
git fetch origin pull/$ID/head:$branch_name
```

# Change origin url

```bash
git remote set-url origin new.git.url/here
```
 
# Disable push

```bash
git remote set-url --push origin no_push
```

# Add signoff

```bash
# for the last 3 commits
git rebase HEAD~3 --signoff
```

# Clean git reflog

```bash

git -c gc.reflogExpire=0 -c gc.reflogExpireUnreachable=0 -c gc.rerereresolved=0 \
    -c gc.rerereunresolved=0 -c gc.pruneExpire=now gc

```

References:
- https://stackoverflow.com/a/14728706
