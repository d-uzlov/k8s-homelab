#!/mnt/c/Windows/System32/WindowsPowerShell/v1.0//powershell.exe -File

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
