#!/mnt/c/Windows/System32/WindowsPowerShell/v1.0//powershell.exe -File

# This is a personal file.
# It fixes a bug in Windows when there can sometimes be duplicated keyboard layout entries
# which make language switching unreliable.
# These layouts are not listed by Windows, so we first add them, and then remove them.

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
