@echo off
echo ================================================================================
	set DisplayLog=No
	set MyLog=SuperISO
echo ================================================================================
	echo Checking Validation
	call "%MakePE%\Scripts\MakePE-Validation.cmd"
	echo "%MakePE%\Scripts\MakePE-Validation.cmd"

echo ================================================================================
	echo Checking for Primary Bootloader Version
	if exist "%BUILDS%\ISO-Support\WinPE10x86\." set SuperISOVer=WinPE10x86
	if exist "%BUILDS%\ISO-Support\WinPE10x64\." set SuperISOVer=WinPE10x64
echo ================================================================================
	echo Setting SuperISO Directory
	set SUPERISODIR=%BUILDS%\SuperISO
	echo %SUPERISODIR%
echo ================================================================================
	echo Copying WinPE Boot to SuperISO
	
	::	Copy WinPE 10 if Version supports it
	If "%SuperISOVer%" == "WinPE10x86" robocopy "%BUILDS%\ISO-Support\WinPE10x86" "%SUPERISODIR%\ISO" *.* /mir /ndl /nfl /r:0 /w:0 /xd Sources Support
	If "%SuperISOVer%" == "WinPE10x64" robocopy "%BUILDS%\ISO-Support\WinPE10x64" "%SUPERISODIR%\ISO" *.* /mir /ndl /nfl /r:0 /w:0 /xd Sources Support
echo ================================================================================
	::	Determine the Default BIOS.  This should have been set, but we will guess if not
	if "%defaultbios%" == "" call :GuessDefaultBIOS
	echo Default BIOS Boot Entry = %defaultbios%
	if "%defaultuefi%" == "" call :GuessDefaultUEFI
	echo Default UEFI Boot Entry = %defaultuefi%
echo ================================================================================
	echo Copying Completed ISO's to SuperISO
	robocopy "%BUILDS%\ISO-Support" "%SUPERISODIR%\ISO\sources" *.* /mir /ndl /xf Make*.cmd /xd Support
echo ================================================================================
	echo Copying Extra Files
	::Extra Files for All WinPE %WinPEVersion% Configurations
	set SRC=%OPTIONAL%\ExtraFilesISO\WinPE %WinPEVersion%
	if NOT exist "%SRC%\." md "%SRC%"
	robocopy "%SRC%" "%SUPERISODIR%\ISO" *.* /e /ndl /nfl /xj /r:0 /w:0
	
	::Extra Files for WinPE %WinPEVersion% %PLATFORM% Configurations
	set SRC=%OPTIONAL%\ExtraFilesISO\WinPE %WinPEVersion% %PLATFORM%
	if NOT exist "%SRC%\." md "%SRC%"
	robocopy "%SRC%" "%SUPERISODIR%\ISO" *.* /e /ndl /nfl /xj /r:0 /w:0
echo ================================================================================
	echo Determining Valid Entries
	if exist "%SUPERISODIR%\ISO\Sources\WinPE10x86\." set WinPE10x86=Yes
	if exist "%SUPERISODIR%\ISO\Sources\WinPE10x64\." set WinPE10x64=Yes
echo ================================================================================
	echo Setting the BOOT Store
	set STORE=/store "%SUPERISODIR%\ISO\boot\bcd"
	echo %STORE%
echo ================================================================================
	echo Setting the WINLOAD
	set WINLOAD=\windows\system32\boot\winload.exe
	echo %WINLOAD%
echo ================================================================================
	echo Deleting Existing BCD
	attrib "%SUPERISODIR%\ISO\boot\bcd" -H -S
	del "%SUPERISODIR%\ISO\boot\bcd" /F
echo ================================================================================
	echo Creating New BCD
	bcdedit /createstore "%SUPERISODIR%\ISO\boot\bcd"
echo ================================================================================
	echo Adding {BootMgr} entries
	bcdedit %STORE% /create {bootmgr}
	bcdedit %STORE% /set {bootmgr} description "Windows Boot Manager"
	bcdedit %STORE% /set {bootmgr} device boot
	bcdedit %STORE% /set {bootmgr} timeout 30
echo ================================================================================
	echo Adding Ram Disk Options
	bcdedit %STORE% /create {ramdiskoptions}
	bcdedit %STORE% /set {ramdiskoptions} ramdisksdidevice boot
	bcdedit %STORE% /set {ramdiskoptions} ramdisksdipath \boot\boot.sdi
echo ================================================================================
	echo Creating Boot Entries
	if "%WinPE10x86%" == "Yes" call :WinPE10x86
	if "%WinPE10x64%" == "Yes" call :WinPE10x64
echo ================================================================================
	echo Setting Default Entry
	bcdedit %STORE% /default %defaultbios%
echo ================================================================================
	echo Creating BCD Text Files for Reference
	bcdedit %STORE% /v > "%SUPERISODIR%\ISO\boot\BCD Verbose.txt"
	bcdedit %STORE% /enum > "%SUPERISODIR%\ISO\boot\BCD Enum.txt"
echo ================================================================================
echo Setting the UEFI BOOT Store
	set STORE=/store "%SUPERISODIR%\ISO\efi\microsoft\boot\bcd"
	echo %STORE%
echo ================================================================================
echo Setting the WINLOAD
	set WINLOAD=\windows\system32\boot\winload.efi
	echo %WINLOAD%
echo ================================================================================
echo Deleting Existing BCD
	attrib "%SUPERISODIR%\ISO\efi\microsoft\boot\bcd" -H -S
	del "%SUPERISODIR%\ISO\efi\microsoft\boot\bcd" /F
echo ================================================================================
echo Creating New BCD
	bcdedit /createstore "%SUPERISODIR%\ISO\efi\microsoft\boot\bcd"
echo ================================================================================
echo Adding {BootMgr} entries
	bcdedit %STORE% /create {bootmgr}
	bcdedit %STORE% /set {bootmgr} description "Windows Boot Manager"
	bcdedit %STORE% /set {bootmgr} device boot
	::	bcdedit %STORE% /set {bootmgr} locale en-US
	bcdedit %STORE% /set {bootmgr} timeout 30
echo ================================================================================
echo Adding Ram Disk Options
	bcdedit %STORE% /create {ramdiskoptions}
	bcdedit %STORE% /set {ramdiskoptions} ramdisksdidevice boot
	bcdedit %STORE% /set {ramdiskoptions} ramdisksdipath \boot\boot.sdi
echo ================================================================================
set prefix=UEFI 
echo Creating Boot Entries
	if "%WinPE10x86%" == "Yes" call :WinPE10x86
	if "%WinPE10x64%" == "Yes" call :WinPE10x64
echo ================================================================================
echo Setting Default Entry
	bcdedit %STORE% /default %defaultuefi%
echo ================================================================================
echo Creating BCD Text Files for Reference
	bcdedit %STORE% /v > "%SUPERISODIR%\ISO\efi\microsoft\boot\BCD Verbose.txt"
	bcdedit %STORE% /enum > "%SUPERISODIR%\ISO\efi\microsoft\boot\BCD Enum.txt"
echo ================================================================================
echo Deleting Existing SuperISO
	del "%BUILDS%\ISO\WinPE SuperISO.iso" /F /Q
echo ================================================================================
set OSCDIMG=%BUILDS%\ISO-Support\Support\%SuperISOVer%\oscdimg.exe
set ETFSBOOT=%BUILDS%\ISO-Support\Support\%SuperISOVer%\etfsboot.com
set EFISYS=%BUILDS%\ISO-Support\Support\%SuperISOVer%\efisys.bin
echo ================================================================================
echo Creating ISO
	"%OSCDIMG%" -bootdata:2#p0,e,b"%ETFSBOOT%"#pEF,e,b"%EFISYS%" -u1 -udfver102 -l"WinPE SuperISO" "%SUPERISODIR%\ISO" "%BUILDS%\ISO\WinPE SuperISO.iso"
echo ================================================================================
rd "%BUILDS%\ISO-Support" /S /Q
rd "%BUILDS%\SuperISO" /S /Q
exit /b


:GuessDefaultBIOS
::	Make the priority x86.  Last entry wins
	if exist "%BUILDS%\ISO-Support\WinPE10x64\." set defaultbios={aaaaaaaa-1064-aaaa-aaaa-aaaaaaaaaaaa}
	if exist "%BUILDS%\ISO-Support\WinPE10x86\." set defaultbios={aaaaaaaa-1032-aaaa-aaaa-aaaaaaaaaaaa}
goto :eof

:GuessDefaultUEFI
::	Make the priority x64.  Last entry wins
	if exist "%BUILDS%\ISO-Support\WinPE10x86\." set defaultuefi={aaaaaaaa-1032-aaaa-aaaa-aaaaaaaaaaaa}
	if exist "%BUILDS%\ISO-Support\WinPE10x64\." set defaultuefi={aaaaaaaa-1064-aaaa-aaaa-aaaaaaaaaaaa}
goto :eof

:CreateEntry
	bcdedit %STORE% /create %guid% /application osloader /d "%name%"
	bcdedit %STORE% /set %guid% device ramdisk=[boot]\%bootwim%,{ramdiskoptions}
	bcdedit %STORE% /set %guid% path %WINLOAD%
	bcdedit %STORE% /set %guid% locale en-US
	bcdedit %STORE% /set %guid% inherit {bootloadersettings}
	bcdedit %STORE% /set %guid% osdevice ramdisk=[boot]\%bootwim%,{ramdiskoptions}
	bcdedit %STORE% /set %guid% systemroot \windows
	bcdedit %STORE% /set %guid% bootmenupolicy Legacy
	bcdedit %STORE% /set %guid% detecthal Yes
	bcdedit %STORE% /set %guid% winpe Yes
	bcdedit %STORE% /set %guid% ems No
	bcdedit %STORE% /displayorder %guid% /addlast
	goto :eof


:WinPE10x86
	set name=%prefix%WinPE 10 x86 (Windows 10 x86)
	set guid={aaaaaaaa-1032-aaaa-aaaa-aaaaaaaaaaaa}
	set bootwim=sources\WinPE10x86\sources\boot.wim
	call :CreateEntry
goto :eof

:WinPE10x64
	set name=%prefix%WinPE 10 x64 (Windows 10 x64)
	set guid={aaaaaaaa-1064-aaaa-aaaa-aaaaaaaaaaaa}
	set bootwim=sources\WinPE10x64\sources\boot.wim
	call :CreateEntry
goto :eof

