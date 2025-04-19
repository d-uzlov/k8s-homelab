
# Krew

Krew is the plugin manager for kubectl command-line tool.

References:
- https://krew.sigs.k8s.io/

# Install

Prerequisites:
- [.bashrc directory](../../docs/bash-setup.md#add-bashrc-directory)

References:
- https://krew.sigs.k8s.io/docs/user-guide/setup/install/

```bash

(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

 cat << "EOF" > ~/.bashrc.d/25-krew.sh
export PATH="$PATH:${KREW_ROOT:-$HOME/.krew}/bin"
EOF

kl krew update
kl krew search

# as an example, install df-pv
# https://github.com/yashbhutwala/kubectl-df-pv
kl krew install df-pv
kl df-pv
kl krew upgrade
kl krew uninstall df-pv

```
