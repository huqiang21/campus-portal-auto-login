' Hidden launcher: runs auto-login.ps1 sitting next to this file,
' with no console window. Add a 5s delay so DHCP/DNS settles first.
Set fso = CreateObject("Scripting.FileSystemObject")
base = fso.GetParentFolderName(WScript.ScriptFullName)
Set sh = CreateObject("WScript.Shell")
WScript.Sleep 5000
sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & base & "\auto-login.ps1""", 0, False
