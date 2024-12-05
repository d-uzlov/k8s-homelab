
# Install

```bash
# check out the latest release
# https://go.dev/doc/devel/release
release=1.23.0
filename=go$release.linux-amd64.tar.gz
curl -OL https://golang.org/dl/$filename &&
rm -rf /usr/local/go &&
sudo tar -C /usr/local -xzf $filename &&
rm $filename

cat << "EOF" > ~/.bashrc.d/0-gopath.sh
export PATH=$PATH:/usr/local/go/bin
EOF
. ~/.bashrc.d/0-gopath.sh

go install golang.org/x/tools/gopls@latest
```

# VSCode set GO OS

https://github.com/microsoft/vscode-go/issues/632#issuecomment-299267102

`toolsEnvVars -> "GOOS" : "linux"`

`toolsEnvVars` can be found in extension settings.

Note that this will break local debugger on Windows.

# Test timeout

Search for `go.testTimeout` in settings.
