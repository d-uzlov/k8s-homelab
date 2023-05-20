
# Setup

```bash
git config --global user.email "exampleexample@example"
git config --global user.name "example example"
```

# Checkout a branch from a pull request

```bash
ID=1440
BRANCHNAME=fix_discoverforwarder
git fetch origin pull/$ID/head:$BRANCHNAME
```

# Disable push

```bash
git remote set-url --push origin no_push
```

# Add signoff

```bash
git rebase HEAD~3 --signoff
```
