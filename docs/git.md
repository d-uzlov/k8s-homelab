
# Setup

```bash
git config --global user.email "example@example"
git config --global user.name "FirstName LastName"
```

# Checkout a branch from a pull request

```bash
ID=1440
BRANCHNAME=pull-request-branch-name
git fetch origin pull/$ID/head:$BRANCHNAME
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
