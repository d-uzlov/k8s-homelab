
# Set ENV

List current variables:

```powershell
Write-Host "Machine environment variables"
[Environment]::GetEnvironmentVariables("Machine")

Write-Host "User environment variables"
[Environment]::GetEnvironmentVariables("User")

# This should be the same as 'Get-ChildItem env:', although it isn't sorted.
Write-Host "Process environment variables"
[Environment]::GetEnvironmentVariables("Process")
```

Change ENVs:

```powershell
# Check env
echo $env:GOPATH
[Environment]::GetEnvironmentVariable('GOPATH', 'User')
# Set env
[Environment]::SetEnvironmentVariable('GOPATH', "J:\go", "User")
```

References:
- https://stackoverflow.com/questions/5898131/set-a-persistent-environment-variable-from-cmd-exe
- https://learn.microsoft.com/en-us/dotnet/api/system.environment.setenvironmentvariable
- https://stackoverflow.com/questions/30675480/windows-user-environment-variable-vs-system-environment-variable

