
# Install

Prerequisites:
- [.bashrc directory](./bash-setup.md#add-bashrc-directory)

```bash

# check out the latest release
# https://go.dev/doc/devel/release
release=1.24.2
filename=go$release.linux-amd64.tar.gz
curl -OL https://golang.org/dl/$filename &&
sudo rm -rf /usr/local/go &&
sudo tar -C /usr/local -xzf $filename &&
rm $filename

cat << "EOF" > ~/.bashrc.d/0-gopath.sh
if [[ $PATH != *"/usr/local/go/bin"* ]];then
export PATH=$PATH:/usr/local/go/bin
fi
if [[ $PATH != *"$HOME/go/bin/"* ]];then
export PATH=$PATH:$HOME/go/bin/
fi
EOF
. ~/.bashrc.d/0-gopath.sh

# if doing development in golang
go install golang.org/x/tools/gopls@latest

```

# VSCode set GO OS

https://github.com/microsoft/vscode-go/issues/632#issuecomment-299267102

`toolsEnvVars -> "GOOS" : "linux"`

`toolsEnvVars` can be found in extension settings.

Note that this will break local debugger on Windows.

# Test timeout

Search for `go.testTimeout` in settings.
