@echo off

:CreateISOTaskList
	call :ISO-CreateDirectory
	call :ISO-ExportWIM
	call :ISO-TempDir
	call :Add-ExtraFilesISO
	call :ISO-CreateISO
	call :ISO-Cleanup
	goto ISO-TheEnd


:ISO-CreateDirectory
	echo.
	echo.
	echo.
	echo.
	echo.
	echo ===============================================================================
	echo Section ISO-CreateDirectory ===================================================
	echo ===============================================================================
	if /I "%DoPause%" == "Yes" pause
	if NOT exist "%BUILDS%\ISO-Support\." echo Creating %BUILDS%\ISO-Support
	if NOT exist "%BUILDS%\ISO-Support\." md "%BUILDS%\ISO-Support"
	if NOT exist "%BUILDS%\ISO\." md "%BUILDS%\ISO"
	echo Deleting Existing %ISOBuild% Directory
	rd "%ISOBuild%" /S /Q
	echo Creating %ISOBuild% Directory
	md "%ISOBuild%"
	echo Creating %ISOBuild% Required Directories
	md "%ISOBuild%\boot"
	md "%ISOBuild%\efi"
	md "%ISOBuild%\sources"
	echo ===============================================================================
	:: if exist "%BUILDS%\MyISO\Sources\Boot.wim" set ISOBuild=%BUILDS%\MyISO
	echo ===============================================================================
	if %WinPEVersion% NEQ 3 echo Copying Boot Files from "%WindowsKit%\Assessment and Deployment Kit\Windows Preinstallation Environment\%PLATFORMARCHITECTURE%\Media" to "%ISOBuild%"
	if %WinPEVersion% NEQ 3 xcopy /cherky "%WindowsKit%\Assessment and Deployment Kit\Windows Preinstallation Environment\%PLATFORMARCHITECTURE%\Media" "%ISOBuild%\"
	echo ===============================================================================
	goto :eof
	
:ISO-ExportWIM
	echo.
	echo.
	echo.
	echo.
	echo.
	echo ===============================================================================
	echo Section ISO-ExportWIM =========================================================
	echo ===============================================================================
	if /I "%DoPause%" == "Yes" pause
	echo Exporting WIM using Command:
	if %WinPEVersion% NEQ 3 set sCMD="%dism%" /Export-Image /Bootable /SourceImageFile:"%ISOSourceImageFile%" /SourceIndex:1 /DestinationImageFile:"%ISODestinationImageFile%" /DestinationName:"%ISOLabel%"
	echo %sCMD%
	%sCMD%
	echo ===============================================================================
	goto :eof
	
:ISO-TempDir
	echo.
	echo.
	echo.
	echo.
	echo.
	echo ===============================================================================
	echo Section ISO-TempDir ===========================================================
	echo ===============================================================================
	if /I "%DoPause%" == "Yes" pause
	echo Creating Working Directory
	
	set ISOBuildTemp=%BUILDS%\ISO-Support\Temp
	robocopy "%ISOBuild%" "%ISOBuildTemp%" *.* /mir /ndl /nfl /xj /r:0 /w:0
	echo ===============================================================================
	goto :eof
	
:ISO-CreateISO
	echo.
	echo.
	echo.
	echo.
	echo.
	echo ===============================================================================
	echo Section ISO-CreateISO =========================================================
	echo ===============================================================================
	if /I "%DoPause%" == "Yes" pause
	echo Creating ISO using Command:
	set sCMD="%OSCDIMG%" -bootdata:2#p0,e,b"%ETFSBOOT%"#pEF,e,b"%EFISYS%" -u1 -udfver102 -l"%ISOLabel%" "%ISOBuildTemp%" "%ISODestination%"
	echo %sCMD%
	%sCMD%

	set sCMD="%OSCDIMG%" -bootdata:2#p0,e,b"%ETFSBOOT%"#pEF,e,b"%EFISYS%" -u1 -udfver102 -l"WinPE %WinPEVersion% %PLATFORM%" "%ISOBuild%" "%ISODestination%"
	echo %sCMD% > "%BUILDS%\ISO-Support\Make ISO WinPE %WinPEVersion% %PLATFORM% - No ExtraFiles.cmd"
	echo pause >> "%BUILDS%\ISO-Support\Make ISO WinPE %WinPEVersion% %PLATFORM% - No ExtraFiles.cmd"
	::	Set back to original values for Cleanup
	
	echo ===============================================================================
	goto :eof

:ISO-Cleanup
	echo.
	echo.
	echo.
	echo.
	echo.
	echo ===============================================================================
	echo Section ISO-Cleanup ===========================================================
	echo ===============================================================================
	if /I "%DoPause%" == "Yes" pause
	echo Deleting Existing %ISOBuildTemp% Directory
	rd "%ISOBuildTemp%" /S /Q
	set ISODestination=
	set ISOLabel=
	echo ===============================================================================
	goto :eof

:ISO-TheEnd
	echo.
	echo.
	echo.
	echo.
	echo.
	echo ===============================================================================
	echo MakePE-BuildISO.cmd Script is Complete =======================================
	echo ===============================================================================
	goto :eof
	
:Add-ExtraFilesISO
	echo.
	echo.
	echo.
	echo.
	echo.
	echo ===============================================================================
	echo Section Add-ExtraFilesISO =====================================================
	echo ===============================================================================
	
	::Extra Files for All WinPE %WinPEVersion% Configurations
	set SRC=%OPTIONAL%\ExtraFilesISO\WinPE %WinPEVersion%
	if NOT exist "%SRC%\." md "%SRC%"
	robocopy "%SRC%" "%ISOBuildTemp%" *.* /e /ndl /nfl /xj /r:0 /w:0
	
	::Extra Files for WinPE %WinPEVersion% %PLATFORM% Configurations
	set SRC=%OPTIONAL%\ExtraFilesISO\WinPE %WinPEVersion% %PLATFORM%
	if NOT exist "%SRC%\." md "%SRC%"
	robocopy "%SRC%" "%ISOBuildTemp%" *.* /e /ndl /nfl /xj /r:0 /w:0
	echo ===============================================================================
	goto :eof
