wpeinit
wpeutil disablefirewall
powershell Set-ExecutionPolicy bypass
powershell -Command "New-Service -Name sshd -BinaryPathName x:\windows\system32\sshd.exe"
net start sshd
powershell x:\windows\system32\wie_start.ps1