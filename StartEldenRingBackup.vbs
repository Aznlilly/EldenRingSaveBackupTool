Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -NoProfile -File ""EldenRingSaveBackup.ps1""", 0, False
