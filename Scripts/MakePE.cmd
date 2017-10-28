@echo off

::Set MakePE Version
	set MakePEVersion=20151014
	set WinPEVersion=10
	
::Set MakePE Directory
	for %%A in ("%~dp0..") do @set MakePE=%%~fA

::	Execute Build BasePE
	
	call :WinPEBuildSequence
	goto StopScript

:WinPEBuildSequence
	echo ===============================================================================
	echo Starting BasePEBuildSequence
	echo ===============================================================================
	::	Check Validation
		call "%MakePE%\Scripts\MakePE-Validation.cmd"
		
	::	WIM Cleanup
		call :WIM-Cleanup
	
	::	WIM Mount
		call :WIM-Mount
		
	::	Install AIK ADK Packages
		call "%SCRIPTS%\Install-Packages.cmd"
	
	::	Install Drivers from %OPTIONAL%\Drivers
		call :Install-Drivers
	
	::	Install Extra Files
		call :Add-ExtraFiles
		
	::	Commit BasePE
		call :WIM-Commit
		
		call :Create-BCD
		
	::	Build the ISO
		if /I %CreateISO% EQU true call "%SCRIPTS%\MakePE-BuildISO.cmd"
			
		exit /b
		
:WIM-Cleanup
	echo.
	echo.
	echo.
	echo.
	echo.
	echo ===============================================================================
	echo Section WIM-Cleanup ===========================================================
	echo ===============================================================================
	
	::	Check for Existing BasePE
	del "%WIMBasePE%" /F /Q
		
	echo Unmounting WIM using Command:
	if %WinPEVersion% NEQ 3 set sCMD="%dism%" /Unmount-WIM /MountDir:"%CONTENT%" /Discard
	echo %sCMD%
	%sCMD%
	echo ===============================================================================
	echo Performing WIM Cleanup using Command:
	if %WinPEVersion% NEQ 3 set sCMD="%dism%" /Cleanup-Wim
	echo %sCMD%
	%sCMD%
	echo ===============================================================================
	if %WinPEVersion% NEQ 3 echo Cleaning Mount Points using Command:
	if %WinPEVersion% NEQ 3 set sCMD="%dism%" /Cleanup-Mountpoints
	if %WinPEVersion% NEQ 3 echo %sCMD%
	if %WinPEVersion% NEQ 3 %sCMD%
	echo ===============================================================================
	echo Deleting Existing Mount Directory %CONTENT%
	rd "%CONTENT%" /S /Q
	if exist "%WIMTemp%" echo Deleting Existing Temp WinPE WIM at %WIMTemp%
	if exist "%WIMTemp%" del "%WIMTemp%" /F /Q
	echo ===============================================================================
	
	goto :eof
	
:WIM-Mount
	echo.
	echo.
	echo.
	echo.
	echo.
	echo ===============================================================================
	echo Section WIM-Mount =============================================================
	echo ===============================================================================
	if /I "%DoPause%" == "Yes" pause
	echo ===============================================================================

	echo Creating Mount Directory at %CONTENT%
	md "%CONTENT%"
	echo ===============================================================================
	echo Deleting Existing WinPE WIM at "%WIMWinPE%"
	if exist "%WIMWinPE%" del "%WIMWinPE%" /f /q
	echo ===============================================================================
	echo Exporting New WIM using Command:
	if %WinPEVersion% NEQ 3 set sCMD="%dism%" /Export-Image /Bootable /SourceImageFile:"%MyWim%" /SourceIndex:1 /DestinationImageFile:"%WIMTemp%" /DestinationName:"Microsoft %WIMName%"
	echo %sCMD%
	%sCMD%
	echo ===============================================================================
	echo Mounting WIM using Command:
	set sCMD="%dism%" /Mount-Image /ImageFile:"%WIMTemp%" /Index:1 /MountDir:"%CONTENT%"
	echo %sCMD%
	%sCMD%
	
	if /I "%PLATFORM%" == "x86" (
		if NOT "%ADK10%" == "Not Found" robocopy "%CONTENT%\Windows\Boot\EFI" "%BUILDS%\tftpboot\static\winpe\winpe_efi_32" bootmgfw.efi /njh /njs /ndl /nfl /r:0 /w:0
		if NOT "%ADK10%" == "Not Found" robocopy "%CONTENT%\Windows\Boot\EFI" "%BUILDS%\tftpboot\proxy\efi32" bootmgfw.efi /njh /njs /ndl /nfl /r:0 /w:0
	)
	if /I "%PLATFORM%" == "x64" (
		if NOT "%ADK10%" == "Not Found" robocopy "%CONTENT%\Windows\Boot\EFI" "%BUILDS%\tftpboot\static\winpe\winpe_efi_64" bootmgfw.efi /njh /njs /ndl /nfl /r:0 /w:0
		if NOT "%ADK10%" == "Not Found" robocopy "%CONTENT%\Windows\Boot\EFI" "%BUILDS%\tftpboot\proxy\efi64" bootmgfw.efi /njh /njs /ndl /nfl /r:0 /w:0
	)
	if NOT "%ADK10%" == "Not Found" robocopy "%CONTENT%\Windows\Boot\PXE" "%BUILDS%\tftpboot\static\winpe\winpe" pxeboot.com pxeboot.n12 bootmgr.exe /njh /njs /ndl /nfl /r:0 /w:0
	if NOT "%ADK10%" == "Not Found" robocopy "%CONTENT%\Windows\Boot\PXE" "%BUILDS%\tftpboot\proxy\bios" pxeboot.com pxeboot.n12 bootmgr.exe /njh /njs /ndl /nfl /r:0 /w:0
	if NOT "%ADK10%" == "Not Found" robocopy "%CONTENT%\Windows\Boot\PXE" "%BUILDS%\tftpboot" bootmgr.exe /njh /njs /ndl /nfl /r:0 /w:0
	
	echo ===============================================================================
	echo Setting TargetPath using Command:
	set sCMD="%dism%" /image:"%CONTENT%" /Set-TargetPath:X:\
	echo %sCMD%
	%sCMD%
	echo ===============================================================================
	echo Setting ScratchSpace using Command:
	set sCMD="%dism%" /image:"%CONTENT%" /Set-ScratchSpace:256
	echo %sCMD%
	%sCMD%
	echo ===============================================================================
	echo Setting TimeZone using Command:
	set sCMD="%dism%" /image:"%CONTENT%" /Set-TimeZone:"%TimeZone%"
	echo %sCMD%
	%sCMD%
	echo ===============================================================================
	goto :eof
	

:WIM-Commit
	echo.
	echo.
	echo.
	echo.
	echo.
	echo ===============================================================================
	echo Section BasePE-Commit =========================================================
	echo ===============================================================================
	echo Opening Windows Explorer %CONTENT%
	if /I "%DoPause%" == "Yes" explorer "%CONTENT%"
	if /I "%DoPause%" == "Yes" pause
	echo ===============================================================================	
	echo ===============================================================================
	echo Dism Component Cleanup
	::	https://technet.microsoft.com/en-us/library/Dn613859.aspx
	::if %WinPEVersion% NEQ 3 set sCMD="%dism%" /Image:"%CONTENT%" /Cleanup-Image /StartComponentCleanup /ResetBase
	::echo %sCMD%
	::%sCMD%
	echo ===============================================================================
	echo Unmounting WIM using Command:
	set sCMD="%dism%" /Unmount-Image /MountDir:"%CONTENT%" /Commit
	echo %sCMD%
	%sCMD%
	echo ===============================================================================
	echo Exporting WIM using Command:
	if %WinPEVersion% NEQ 3 set sCMD="%dism%" /Export-Image /Bootable /SourceImageFile:"%WIMTemp%" /SourceIndex:1 /DestinationImageFile:"%WIMBasePE%" /DestinationName:"Microsoft %WIMName%"
	echo %sCMD%
	%sCMD%
	echo ===============================================================================
	 del "%WIMTemp%" /F /Q
	goto :eof

:Install-Drivers
	echo.
	echo.
	echo.
	echo.
	echo.
	echo ===============================================================================
	echo Section Install-Drivers =======================================================
	echo ===============================================================================
	echo Applying Drivers from 
	"%dism%" /Image:"%CONTENT%" /Add-Driver /Driver:"%OPTIONAL%\Drivers\WinPE %WinPEVersion% %PLATFORM%" /Recurse /ForceUnsigned
	echo ===============================================================================
	goto :eof
	
:Add-ExtraFiles
	echo.
	echo.
	echo.
	echo.
	echo.
	echo ===============================================================================
	echo Section Add-ExtraFiles ====================================================
	echo ===============================================================================

	::Extra Files for All WinPE %WinPEVersion% Configurations
	set SRC=%OPTIONAL%\ExtraFiles\WinPE %WinPEVersion%

	robocopy "%SRC%" "%CONTENT%" *.* /e /ndl /nfl /xj /r:0 /w:0
		
	::Extra Files for WinPE %WinPEVersion% %PLATFORM% Configurations
	set SRC=%OPTIONAL%\ExtraFiles\WinPE %WinPEVersion% %PLATFORM%
	robocopy "%SRC%" "%CONTENT%" *.* /e /ndl /nfl /xj /r:0 /w:0
	echo %BaseURL%api/ClientImaging/ > "%CONTENT%\Windows\System32\web.txt"
	if [%UniversalToken%] NEQ [] echo %UniversalToken% > "%CONTENT%\Windows\System32\uToken.txt"
	echo ===============================================================================
	
	goto :eof
	
:Create-BCD
	echo.
	echo.
	echo.
	echo.
	echo.
	echo ===============================================================================
	echo Section Create-BCD ====================================================
	echo ===============================================================================
	if NOT exist "%BUILDS%\tftpboot\boot\." md "%BUILDS%\tftpboot\boot"
	if /I "%PLATFORM%" == "x86" set STORE="%BUILDS%\tftpboot\boot\BCDx86"
	if /I "%PLATFORM%" == "x64" set STORE="%BUILDS%\tftpboot\boot\BCDx64"

echo ================================================================================
	echo Deleting Existing BCD
	attrib %STORE% -H -S
	del %STORE% /F
echo ================================================================================
	echo Creating New BCD
	bcdedit /createstore %STORE%
echo ================================================================================
	echo Adding Ram Disk Options
	bcdedit /store %STORE% /create {ramdiskoptions}
	bcdedit /store %STORE% /set {ramdiskoptions} ramdisksdidevice boot
	bcdedit /store %STORE% /set {ramdiskoptions} ramdisksdipath \boot\boot.sdi	
echo ================================================================================	
	if /I "%PLATFORM%" == "x86" (
		set name="CloneDeploy WinPE 10 x86"
		set guid={aaaaaaaa-1032-aaaa-aaaa-aaaaaaaaaaaa}
		set bootwim="\boot\WinPE10x86.wim"
	)
	if /I "%PLATFORM%" == "x64" (
		set name="CloneDeploy WinPE 10 x64"
		set guid={aaaaaaaa-1064-aaaa-aaaa-aaaaaaaaaaaa}
		set bootwim="\boot\WinPE10x64.wim"
	)
	bcdedit /store %STORE% /create %guid% /application osloader /d %name%
	bcdedit /store %STORE% /set %guid% systemroot \windows
	bcdedit /store %STORE% /set %guid% detecthal Yes
	bcdedit /store %STORE% /set %guid% winpe Yes
	bcdedit /store %STORE% /set %guid% osdevice ramdisk=[boot]%bootwim%,{ramdiskoptions}
	bcdedit /store %STORE% /set %guid% device ramdisk=[boot]%bootwim%,{ramdiskoptions}

	echo Adding {BootMgr} entries
	bcdedit /store %STORE% /create {bootmgr} /d "Windows Boot Manager"
	bcdedit /store %STORE% /set {bootmgr} timeout 30
	bcdedit /store %STORE% /displayorder %guid% /addlast
	goto :eof
	
:StopScript
	echo.
	echo.
	echo.
	echo.
	echo.
	echo ===============================================================================
	echo Script Processing has Stopped =================================================
	echo ===============================================================================
	exit /b