
# Install

```bash
curl -OL https://golang.org/dl/go1.22.2.linux-amd64.tar.gz &&
rm -rf /usr/local/go &&
sudo tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz

# if you don't have it already in path
export PATH=$PATH:/usr/local/go/bin
```

# VSCode set GO OS

https://github.com/microsoft/vscode-go/issues/632#issuecomment-299267102

`toolsEnvVars -> "GOOS" : "linux"`

`toolsEnvVars` can be found in extension settings.

Note that this will break local debugger on Windows.

# Test timeout

Search for `go.testTimeout` in settings.
