
# search history by prefix with ↑

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

# Useful prompt

Add to your `~/.bashrc`:
```bash
PROMPT_COMMAND=__prompt_command    # Function to generate PS1 after CMDs

__prompt_command() {
    local EXIT="$?"                # This needs to be first
    PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]"

    local reset_color='\[\e[0m\]'

    local Red='\[\e[0;31m\]'
    local Gre='\[\e[0;32m\]'
    local BYel='\[\e[1;33m\]'
    local BBlu='\[\e[1;34m\]'
    local Pur='\[\e[0;35m\]'

    if [ $EXIT != 0 ]; then
        code_color="${Red}"
        PS1+="$code_color"
        PS1+=' \\$? == '
        PS1+="$EXIT"
        PS1+="${reset_color}"
    else
        code_color="${BYel}"
    fi
    PS1+="\n"
    PS1+="$code_color"
    PS1+="\$"
    PS1+="${reset_color}"
    PS1+=" "
}
```

# Docker completion

```bash
sudo curl https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker -o /etc/bash_completion.d/docker.sh
```

# Kubectl completion

```bash
source <(kind completion bash)
source <(kubectl completion bash)

alias k=kubectl
complete -o default -F __start_kubectl k

function createKubectlAlias() {
    name=$1
    config=$2
    . <(echo 'function '$name'() { kubectl --kubeconfig "'"$config"'" "$@"; }; export -f '$name'; alias '$name'="kubectl --kubeconfig='$config'"; complete -o default -F __start_kubectl '$name)
}

export KUBECONFIGLOCAL=/mnt/c/Users/danil/Documents/k8s-public-copy/_env/cp.k8s.lan.yaml

createKubectlAlias kl "$KUBECONFIGLOCAL"

export KUBECONFIG1=/tmp/kind-configs/kubeconfig-kind
export KUBECONFIG2=/tmp/kind-configs/kubeconfig-kind-2
export KUBECONFIG3=/tmp/kind-configs/kubeconfig-kind-3
export KUBECONFIG=$KUBECONFIG1

export CLUSTER1_CIDR=172.18.201.0/24
export CLUSTER2_CIDR=172.18.202.0/24
export CLUSTER3_CIDR=172.18.203.0/24

createKubectlAlias k1 "$KUBECONFIG1"
createKubectlAlias k2 "$KUBECONFIG2"
createKubectlAlias k3 "$KUBECONFIG3"
```

# Print CPU temperature without external tools

```bash
paste <(cat /sys/class/thermal/thermal_zone*/type) <(cat /sys/class/thermal/thermal_zone*/temp) | column -s $'\t' -t | sed 's/\(.\)..$/.\1°C/'
```
