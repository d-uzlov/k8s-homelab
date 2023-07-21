
# Remove non-existent keyboard layouts

```powershell
$LanguageList = Get-WinUserLanguageList
($LanguageList | Where-Object LanguageTag -like 'en-US').InputMethodTips.Add('0409:A0000409')
($LanguageList | Where-Object LanguageTag -like 'en-US').InputMethodTips.Add('0409:00000409')
($LanguageList | Where-Object LanguageTag -like 'ru').InputMethodTips.Add('0419:A0000419')
($LanguageList | Where-Object LanguageTag -like 'ru').InputMethodTips.Add('0419:00000419')
Set-WinUserLanguageList -Force -LanguageList $LanguageList

$LanguageList = Get-WinUserLanguageList
($LanguageList | Where-Object LanguageTag -like 'en-US').InputMethodTips.Remove('0409:00000409')
($LanguageList | Where-Object LanguageTag -like 'ru').InputMethodTips.Remove('0419:00000419')
Set-WinUserLanguageList -Force -LanguageList $LanguageList
```

# Move WSL installation

```powershell
wsl.exe --export Ubuntu c:\ubuntu.tar
wsl.exe --import UbuntuNewName d:\wsl\Ubuntu c:\ubuntu.tar
# if you don't need the old installation anymore
wsl.exe --unregister <OriginalDistributionName>
wsl --set-default UbuntuNewName

wsl -d UbuntuNewName
# by default WSL will use the root account
# add config file to change it
# fill in the name of your windows account
cat > /etc/wsl.conf <<EOF
[user]
default=<yourAccount>
EOF
```

References:
- https://stackoverflow.com/questions/38779801/move-wsl-bash-on-windows-root-filesystem-to-another-hard-drive
