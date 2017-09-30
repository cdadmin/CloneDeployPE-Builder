@echo off
REM	echo ===============================================================================
	::	Check for Elevation and give the Warning!!!!!!!
	::	http://stackoverflow.com/questions/4051883/batch-script-how-to-check-for-admin-rights/
	net session >nul 2>&1
	if %errorLevel% == 0 (
	echo ===============================================================================
	echo SCRIPT IS RUNNING ADMINISTRATOR ELEVATED AND WILL EXECUTE
	echo ===============================================================================
	) else (
	echo ===============================================================================
	echo YOU MUST RUN AS ADMINISTRATOR ELEVATED TO EXECUTE THIS SCRIPT
	goto :StopScript
	echo ===============================================================================
	)
	
echo ===============================================================================
echo Executing MakePE Validation at %MakePE%\Scripts\MakePE-Validation.cmd
echo ===============================================================================
	
	set BUILDS=%MakePE%\Builds
	echo Checking MakePE Core Directories
	if %Pass% EQU 1 (
		rd "%BUILDS%" /S /Q
		echo Creating BUILDS Directory at %BUILDS%
		md "%BUILDS%"
		if NOT exist "%BUILDS%\tftpboot\boot\." md "%BUILDS%\tftpboot\boot"
		echo ===============================================================================
	)
	
	set OPTIONAL=%MakePE%\Optional
		if NOT exist "%OPTIONAL%\." md "%OPTIONAL%"
		if NOT exist "%OPTIONAL%\Drivers\." md "%OPTIONAL%\Drivers"
		if NOT exist "%OPTIONAL%\Drivers\WinPE 10 x64\." md "%OPTIONAL%\Drivers\WinPE 10 x64"
		if NOT exist "%OPTIONAL%\Drivers\WinPE 10 x86\." md "%OPTIONAL%\Drivers\WinPE 10 x86"
	set SCRIPTS=%MakePE%\Scripts
echo ===============================================================================
	


echo ===============================================================================
	echo Checking ADK Integration for WinPE 10
	echo 	Valid Locations:
	echo 	C:\Program Files\Windows Kits\10\Assessment and Deployment Kit
	echo 	C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit
	echo 	%Components%\Windows Kits\10\Assessment and Deployment Kit
	
::	Set the Directory for ADK 10 (WinPE 10)
	if exist "C:\Program Files\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\copype.cmd" set ADK10=C:\Program Files\Windows Kits\10
	if exist "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\copype.cmd" set ADK10=C:\Program Files (x86)\Windows Kits\10
	
::	Or if ADK 10 is relocated to Components then we will use that copy
	if exist "%Components%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\copype.cmd" set ADK10=%Components%\Windows Kits\10
	if /I "%ADK10%" == "" set ADK10=Not Found
echo ===============================================================================
	if /I "%PLATFORM%" == "x86" set PLATFORMARCHITECTURE=x86
	if /I "%PLATFORM%" == "x64" set PLATFORMARCHITECTURE=amd64
	
	if %WinPEVersion% EQU 10 set WindowsKit=%ADK10%
echo ===============================================================================


echo ===============================================================================
::	Copy Local Support
	if /I %CreateISO% EQU true (
		if NOT "%ADK10%" == "Not Found" robocopy "%ADK10%\Assessment and Deployment Kit\Deployment Tools\amd64\BCDBoot" "%BUILDS%\ISO-Support\Support\WinPE10x64" *.* /njh /njs /ndl /nfl /r:0 /w:0
		if NOT "%ADK10%" == "Not Found" robocopy "%ADK10%\Assessment and Deployment Kit\Deployment Tools\x86\BCDBoot" "%BUILDS%\ISO-Support\Support\WinPE10x86" *.* /njh /njs /ndl /nfl /r:0 /w:0
		if NOT "%ADK10%" == "Not Found" robocopy "%ADK10%\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg" "%BUILDS%\ISO-Support\Support\WinPE10x64" *.* /njh /njs /ndl /nfl /r:0 /w:0
		if NOT "%ADK10%" == "Not Found" robocopy "%ADK10%\Assessment and Deployment Kit\Deployment Tools\x86\Oscdimg" "%BUILDS%\ISO-Support\Support\WinPE10x86" *.* /njh /njs /ndl /nfl /r:0 /w:0
	)
	if NOT "%ADK10%" == "Not Found" robocopy "%ADK10%\Assessment and Deployment Kit\Windows Preinstallation Environment\%PLATFORMARCHITECTURE%\Media\Boot" "%BUILDS%\tftpboot\boot" boot.sdi /njh /njs /ndl /nfl /r:0 /w:0
::	Set location of oscdimg
	if %WinPEVersion% NEQ 3 set OSCDIMG=%WindowsKit%\Assessment and Deployment Kit\Deployment Tools\%PROCESSOR_ARCHITECTURE%\Oscdimg\oscdimg.exe
	if exist "%BUILDS%\ISO-Support\Support\WinPE%WinPEVersion%%PLATFORM%\oscdimg.exe" set OSCDIMG=%BUILDS%\ISO-Support\Support\WinPE%WinPEVersion%%PLATFORM%\oscdimg.exe
	if /I "%WindowsKit%" == "Not Found" set OSCDIMG=Not Found
	
::	Set the location of etfsboot.com
	if %WinPEVersion% NEQ 3 set ETFSBOOT=%WindowsKit%\Assessment and Deployment Kit\Deployment Tools\%PROCESSOR_ARCHITECTURE%\Oscdimg\etfsboot.com
	if exist "%BUILDS%\ISO-Support\Support\WinPE%WinPEVersion%%PLATFORM%\etfsboot.com" set ETFSBOOT=%BUILDS%\ISO-Support\Support\WinPE%WinPEVersion%%PLATFORM%\etfsboot.com
	if /I "%WindowsKit%" == "Not Found" set ETFSBOOT=Not Found
	
::	Set the location of efisys.bin
	if %WinPEVersion% NEQ 3 set EFISYS=%WindowsKit%\Assessment and Deployment Kit\Deployment Tools\%PROCESSOR_ARCHITECTURE%\Oscdimg\efisys.bin
	if exist "%BUILDS%\ISO-Support\Support\WinPE%WinPEVersion%%PLATFORM%\efisys.bin" set EFISYS=%BUILDS%\ISO-Support\Support\WinPE%WinPEVersion%%PLATFORM%\efisys.bin
	if /I "%WindowsKit%" == "Not Found" set EFISYS=Not Found
echo ===============================================================================
::	Set the CAB Directory
	if %WinPEVersion% EQU 10 set CABS=%ADK10%\Assessment and Deployment Kit\Windows Preinstallation Environment\%PLATFORMARCHITECTURE%\WinPE_OCs
	if /I "%WindowsKit%" == "Not Found" set CABS=Not Found
	
::	Set location of DISM
	if %WinPEVersion% EQU 10 set DISM=%ADK10%\Assessment and Deployment Kit\Deployment Tools\%PROCESSOR_ARCHITECTURE%\DISM\dism.exe
	if /I "%WindowsKit%" == "Not Found" set DISM=Not Found
	
::	Set location of ImageX
	if %WinPEVersion% EQU 10 set IMAGEX=%ADK10%\Assessment and Deployment Kit\Deployment Tools\%PROCESSOR_ARCHITECTURE%\DISM\imagex.exe
	if /I "%WindowsKit%" == "Not Found" set IMAGEX=Not Found
echo ===============================================================================
	if %WinPEVersion% NEQ 3 set MyWim=%WindowsKit%\Assessment and Deployment Kit\Windows Preinstallation Environment\%PLATFORMARCHITECTURE%\en-us\winpe.wim
	set WinPEType=WinPE
	
	if exist "%Components%\WinPE %WinPEVersion% %PLATFORM%\Boot.wim" set MyWim=%Components%\WinPE %WinPEVersion% %PLATFORM%\Boot.wim
	if exist "%Components%\WinPE %WinPEVersion% %PLATFORM%\Boot.wim" set WinPEType=Boot
	
	if exist "%Components%\WinPE %WinPEVersion% %PLATFORM%\WinRE.wim" set MyWim=%Components%\WinPE %WinPEVersion% %PLATFORM%\WinRE.wim
	if exist "%Components%\WinPE %WinPEVersion% %PLATFORM%\WinRE.wim" set WinPEType=WinRE
	
	if NOT exist "%MyWim%" set MyWim=
	if NOT exist "%MyWim%" set WinPEType=
echo ===============================================================================
	set CONTENT=%Temp%\%WinPEType%
	
	set WIMTemp=%BUILDS%\TEMP WinPE %WinPEVersion% %PLATFORM% %WinPEType%.wim
	set WIMBasePE=%BUILDS%\tftpboot\boot\WinPE%WinPEVersion%%PLATFORM%.wim
	set WIMName=WinPE %WinPEVersion% %PLATFORM%
echo ===============================================================================
	if /I "%WinPEType%" == "Boot" set WinPE-Scripting=Already Installed
	if /I "%WinPEType%" == "Boot" set WinPE-WMI=Already Installed
	if /I "%WinPEType%" == "Boot" set WinPE-SecureStartup=Already Installed
	if /I "%WinPEType%" == "Boot" set WinPE-WDS-Tools=Already Installed
	
	if /I "%WinPEType%" == "WinRE" set WinPE-Scripting=Already Installed
	if /I "%WinPEType%" == "WinRE" set WinPE-WMI=Already Installed
	if /I "%WinPEType%" == "WinRE" set WinPE-SecureStartup=Already Installed
	if /I "%WinPEType%" == "WinRE" set WinPE-WDS-Tools=Already Installed

	if NOT "%MyLog%" == "SuperISO" set MyLog=%BUILDS%\WinPE %WinPEVersion% %PLATFORM% %WinPEType% Log.txt
	if "%MyLog%" == "SuperISO" set MyLog=%BUILDS%\SuperISO Log.txt

	echo Writing to "%MyLog%"
	echo Version Information:>> "%MyLog%"
	echo 	MakePE Version:  	%MakePEVersion%> "%MyLog%"
	echo ===============================================================================>> "%MyLog%"
	echo MakePE Directory Information:>> "%MyLog%"
	echo 	MakePE Directory:  	%MakePE%>> "%MyLog%"
	echo 	MakePE Builds:  	%BUILDS%>> "%MyLog%"
	echo 	MakePE Components:  	%Components%>> "%MyLog%"
	echo 	MakePE Optional:  	%OPTIONAL%>> "%MyLog%"
	echo 	MakePE Scripts:  	%SCRIPTS%>> "%MyLog%"
	echo ===============================================================================>> "%MyLog%"

	echo AIK and ADK Installation Status:>> "%MyLog%"
	echo 	Windows 10 ADK:		%ADK10%>> "%MyLog%"
	echo ===============================================================================>> "%MyLog%"
	echo WinPE Source Status:>> "%MyLog%"
	echo 	WinPE Version:  	%WinPEVersion% >> "%MyLog%"
	echo 	WinPE Platform:  	%PLATFORM%>> "%MyLog%"
	echo 	WinPE Architecture:  	%PLATFORMARCHITECTURE%>> "%MyLog%"
	echo 	WinPE Language:  	%MyLang%>> "%MyLog%"
	echo 	WinPE WIM:   		%MyWim%>> "%MyLog%"
	echo 	WinPE Type:  		%WinPEType%>> "%MyLog%"
	echo ===============================================================================>> "%MyLog%"
	echo WinPE Mount and Build Status:>> "%MyLog%"
	echo 	WIM Mount Directory:  	%CONTENT%>> "%MyLog%"
	echo 	WIM Temp:   		%WIMTemp%>> "%MyLog%"
	echo 	WIM BasePE:   		%WIMBasePE%>> "%MyLog%"
	echo ===============================================================================>> "%MyLog%"
	echo ISO Status:>> "%MyLog%"
	set ISOSupport=%BUILDS%\ISO-Support\Support
	echo 	ISO Supporting Files:				%ISOSupport%>> "%MyLog%"
	
	set ISOBuild=%BUILDS%\ISO-Support\WinPE%WinPEVersion%%PLATFORM%
	echo 	ISO Source Directory:				%ISOBuild%>> "%MyLog%"
	
	set ISOSourceImageFile=%WIMBasePE%
	echo 	ISO Source WIM:					%ISOSourceImageFile%>> "%MyLog%"
	
	set ISODestinationImageFile=%ISOBuild%\Sources\Boot.wim
	echo 	ISO Destination WIM:				%ISODestinationImageFile%>> "%MyLog%"
	
	if "%ISODestination%" == "" set ISODestination=%BUILDS%\ISO\WinPE %WinPEVersion% %PLATFORM% %WinPEType%.iso
	echo 	ISO Destination (ISODestination):		%ISODestination%>> "%MyLog%"
	
	if "%ISOLabel%" == "" set ISOLabel=WinPE %WinPEVersion% %PLATFORM%
	echo 	ISO Label (ISOLabel):				%ISOLabel%>> "%MyLog%"
	
	set SuperISOBuild=%BUILDS%\SuperISO
	echo 	SuperISO Source Directory:			%SuperISOBuild%>> "%MyLog%"
	
	if "%SuperISODestination%" == "" set SuperISODestination=%BUILDS%\ISO\WinPE SuperISO.iso
	echo 	SuperISO Destination (SuperISODestination):	%SuperISODestination%>> "%MyLog%"
	
	if "%SuperISOLabel%" == "" set SuperISOLabel=WinPE SuperISO
	echo 	SuperISO Label (SuperISOLabel):			%SuperISOLabel%>> "%MyLog%"
	echo ===============================================================================>> "%MyLog%"
	echo Windows Kit Status:>> "%MyLog%"
	echo 	Windows Kit:  		%WindowsKit%>> "%MyLog%"
	echo 	CABS:  			%CABS%>> "%MyLog%"
	echo 	dism.exe:  		%DISM%>> "%MyLog%"
	echo 	imagex.exe:  		%IMAGEX%>> "%MyLog%"
	echo 	oscdimg.exe:  		%OSCDIMG%>> "%MyLog%"
	echo 	etfsboot.com:  		%ETFSBOOT%>> "%MyLog%"
	echo 	efisys.bin:  		%EFISYS%>> "%MyLog%"
	echo ===============================================================================>> "%MyLog%"
	echo MakePE Options:>> "%MyLog%"
	echo 	TimeZone:		%TimeZone%>> "%MyLog%"
	echo ===============================================================================>> "%MyLog%"
	echo WARNINGS:>> "%MyLog%"
	
	REM	echo ===============================================================================
	if /I "%ADK10%" == "Not Found" (
	echo ===============================================================================
	echo Microsoft ADK for Windows 10 was not located
	echo You will not be able to service WinPE 10
	echo Microsoft ADK for Windows 10 was not located.  You will not be able to service WinPE 10 >> "%MyLog%"
	echo ===============================================================================
	if %WinPEVersion% EQU 10 set StopScript=Yes
	)
	
	REM	echo ===============================================================================
	if /I "%WinPEVersion%" == "" (
	echo ===============================================================================
	echo WinPE version was not set properly
	echo WinPE version was not set properly >> "%MyLog%"
	echo ===============================================================================
	set StopScript=Yes
	)
	
	REM	echo ===============================================================================
	if /I "%MyLang%" == "" (
	echo ===============================================================================
	echo MyLang was not set with a Language
	echo MyLang was not set with a Language >> "%MyLog%"
	echo ===============================================================================
	set StopScript=Yes
	)
	
	REM	echo ===============================================================================
	if /I "%MyWim%" == "" (
	echo ===============================================================================
	echo Could not determine a WIM file to use
	echo Could not determine a WIM file to use >> "%MyLog%"
	echo ===============================================================================
	set StopScript=Yes
	)
	
	REM	echo ===============================================================================
	if /I "%PLATFORM%" == "" (
	echo ===============================================================================
	echo Platform for WinPE was not set properly
	echo Platform for WinPE was not set properly >> "%MyLog%"
	echo ===============================================================================
	set StopScript=Yes
	)
	
	REM	echo ===============================================================================
	if /I "%BaseURL%" == "http://0.0.0.0/clonedeploy/" (
	echo ===============================================================================
	echo CloneDeploy Web Service Was Not Set
	echo CloneDeploy Web Service Was Not Set >> "%MyLog%"
	echo ===============================================================================
	set StopScript=Yes
	)

	REM	echo ===============================================================================
	echo ===============================================================================>> "%MyLog%"
	if /I "%StopScript%" == "Yes" goto :StopScript
	goto :eof
	
:StopScript
	echo MakePE did not complete properly
	pause
	exit
