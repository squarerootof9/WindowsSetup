@echo off
setlocal enabledelayedexpansion
REM Windows Setup Script to Download Programs and Manage Java

REM Global Variables
set DOWNLOAD_DIR=%USERPROFILE%\Downloads
set JAVA_DIR=C:\JAVA
set LOG_FILE=%DOWNLOAD_DIR%\setup_script.log

REM Check for administrative privileges
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo You must run this script as administrator!
    pause
    exit /b 1
)

REM Check if s_wget.exe is in the current directory or in PATH
where s_wget.exe >nul 2>&1
if errorlevel 1 (
    echo s_wget.exe not found. Please ensure s_wget.exe is in the current directory or in your PATH.
    pause
    exit /b 1
)

:MENU
cls
echo --------------------------------------------
echo Setup Script Menu
echo --------------------------------------------
echo 1) Add/Remove Java
echo 2) Add All Programs
echo 3) Add Individual Programs
echo 4) Exit
echo --------------------------------------------
set /p choice=Please select an option [1-4]: 
if "%choice%"=="1" goto AddOrRemoveJava
if "%choice%"=="2" goto AddAllPrograms
if "%choice%"=="3" goto AddIndividualPrograms
if "%choice%"=="4" goto ExitScript
echo Invalid option. Please try again.
pause
goto MENU

:AddOrRemoveJava
REM Check if Java is installed by running 'java -version'
java -version >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Java is currently installed.
    set /p "removeJava=Do you want to remove Java? (y/N): "
    if /i "%removeJava%"=="Y" (
        set "NextAction=RemoveJava"
    ) else (
        set "NextAction=MENU"
    )
) else (
    echo Java is not installed.
    set /p "installJava=Do you want to install Java? (y/N): "
    if /i "%installJava%"=="Y" (
        set "NextAction=InstallJava"
    ) else (
        set "NextAction=MENU"
    )
)
goto !NextAction!

:InstallJava
REM Variables for Java installation
set DOWNLOAD_URL=https://download.java.net/java/GA/jdk23.0.1/c28985cbf10d4e648e4004050f8781aa/11/GPL/openjdk-23.0.1_windows-x64_bin.zip

REM Create the download directory if it doesn't exist
if not exist "%DOWNLOAD_DIR%" (
    mkdir "%DOWNLOAD_DIR%"
)

REM Download the Java ZIP file
echo Downloading Java...
echo Downloading Java... >> "%LOG_FILE%"
s_wget.exe "%DOWNLOAD_URL%" -O "%DOWNLOAD_DIR%\openjdk-23.0.1_windows-x64_bin.zip"
if errorlevel 1 (
    echo Failed to download Java.
    echo Failed to download Java. >> "%LOG_FILE%"
    pause
    goto MENU
)

REM Create the Java directory if it doesn't exist
if not exist "%JAVA_DIR%" (
    mkdir "%JAVA_DIR%"
)

REM Extract the ZIP file using PowerShell
echo Extracting Java...
echo Extracting Java... >> "%LOG_FILE%"
powershell -Command "Expand-Archive -Path '%DOWNLOAD_DIR%\openjdk-23.0.1_windows-x64_bin.zip' -DestinationPath '%JAVA_DIR%' -Force"
if errorlevel 1 (
    echo Failed to extract Java.
    echo Failed to extract Java. >> "%LOG_FILE%"
    pause
    goto MENU
)

REM Get the current system PATH variable
for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path') do set "SYSPATH=%%B"

REM Update the system PATH variable
set "NEWPATH=%SYSPATH%;%JAVA_DIR%\jdk-23.0.1\bin"

REM Update PATH variable in the registry
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path /t REG_EXPAND_SZ /d "%NEWPATH%" /f
if errorlevel 1 (
    echo Failed to update PATH variable.
    echo Failed to update PATH variable. >> "%LOG_FILE%"
    pause
    goto MENU
)

REM Set JAVA_HOME environment variable
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v JAVA_HOME /t REG_SZ /d "%JAVA_DIR%\jdk-23.0.1" /f
if errorlevel 1 (
    echo Failed to set JAVA_HOME variable.
    echo Failed to set JAVA_HOME variable. >> "%LOG_FILE%"
    pause
    goto MENU
)

echo Java has been installed and environment variables have been updated.
echo Java has been installed and environment variables have been updated. >> "%LOG_FILE%"
echo Please restart your computer or log off and log back in for changes to take effect.
echo Please restart your computer or log off and log back in for changes to take effect. >> "%LOG_FILE%"
pause
goto MENU

:RemoveJava
REM Remove Java
echo Removing Java...
echo Removing Java... >> "%LOG_FILE%"

REM Unset JAVA_HOME environment variable
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v JAVA_HOME /f

REM Remove Java from PATH variable
for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path') do set "SYSPATH=%%B"
set "NEWPATH=%SYSPATH%"
call set "NEWPATH=%%NEWPATH:%JAVA_DIR%\jdk-23.0.1\bin;=%%"

REM Update PATH variable in the registry
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path /t REG_EXPAND_SZ /d "%NEWPATH%" /f

REM Remove Java installation directory
if exist "%JAVA_DIR%" (
    rd /s /q "%JAVA_DIR%"
) else (
    echo Java directory "%JAVA_DIR%" does not exist.
    echo Java directory "%JAVA_DIR%" does not exist. >> "%LOG_FILE%"
)

echo Java has been removed.
echo Java has been removed. >> "%LOG_FILE%"
echo Please restart your computer or log off and log back in for changes to take effect.
echo Please restart your computer or log off and log back in for changes to take effect. >> "%LOG_FILE%"
pause
goto MENU

:AddAllPrograms
REM Read programs from app_list.txt
set ProgramCount=0

if not exist "app_list.txt" (
    echo Error: app_list.txt not found.
    echo Error: app_list.txt not found. >> "%LOG_FILE%"
    pause
    goto MENU
)

REM Read each line from app_list.txt, skipping comments and empty lines
for /F "usebackq tokens=*" %%G in ("app_list.txt") do (
    set "line=%%G"
    if not "!line!"=="" (
        if not "!line:~0,1!"=="#" (
            set /A ProgramCount+=1
            set "programs[!ProgramCount!]=!line!"
        )
    )
)

if %ProgramCount% EQU 0 (
    echo No programs found in app_list.txt.
    echo No programs found in app_list.txt. >> "%LOG_FILE%"
    pause
    goto MENU
)

REM Display time warning and prompt to proceed
echo This process will download and install all %ProgramCount% programs.
echo This may take a significant amount of time.
set /p "proceed=Do you wish to continue? (Y/N): "
if /I "%proceed%" NEQ "Y" (
    echo Operation cancelled.
    goto MENU
)

REM Build list of all program indices
set "selectedIndices="
for /L %%i in (1,1,%ProgramCount%) do (
    if defined selectedIndices (
        set "selectedIndices=!selectedIndices! %%i"
    ) else (
        set "selectedIndices=%%i"
    )
)

goto ProcessSelectedPrograms

:AddIndividualPrograms
REM Read programs from app_list.txt
set ProgramCount=0

if not exist "app_list.txt" (
    echo Error: app_list.txt not found.
    echo Error: app_list.txt not found. >> "%LOG_FILE%"
    pause
    goto MENU
)

REM Read each line from app_list.txt, skipping comments and empty lines
for /F "usebackq tokens=*" %%G in ("app_list.txt") do (
    set "line=%%G"
    if not "!line!"=="" (
        if not "!line:~0,1!"=="#" (
            set /A ProgramCount+=1
            set "programs[!ProgramCount!]=!line!"
        )
    )
)

if %ProgramCount% EQU 0 (
    echo No programs found in app_list.txt.
    echo No programs found in app_list.txt. >> "%LOG_FILE%"
    pause
    goto MENU
)

REM Display the list of programs
echo Available Programs:
echo Available Programs: >> "%LOG_FILE%"
for /L %%i in (1,1,%ProgramCount%) do (
    set "entry=!programs[%%i]!"
    for /F "tokens=1 delims=|" %%A in ("!entry!") do (
        echo %%i^) %%A
        echo %%i^) %%A >> "%LOG_FILE%"
    )
)
REM Add '0) Exit' option
echo 0^) Exit
echo 0^) Exit >> "%LOG_FILE%"

echo.
set /p "selected=Enter the numbers of the programs to download and install, separated by commas (e.g., 1,3,5): "

REM Parse the user input into selected program indices
set "selectedIndices=%selected%"
set "selectedIndices=%selectedIndices:,= %"

REM Check if user selected '0' to exit
echo %selectedIndices% | findstr /b /c:"0" >nul
if %ERRORLEVEL% EQU 0 (
    goto MENU
)

goto ProcessSelectedPrograms

:ProcessSelectedPrograms
REM Loop over selected indices
for %%i in (%selectedIndices%) do (
    if %%i GEQ 1 if %%i LEQ %ProgramCount% (
        set "entry=!programs[%%i]!"
        for /F "tokens=1,2,3 delims=|" %%A in ("!entry!") do (
            set "progName=%%A"
            set "progURL=%%B"
            set "installSwitches=%%C"
        )
        echo Processing !progName!...
        echo Processing !progName!... >> "%LOG_FILE%"

        REM Download the program
        echo Downloading !progName!...
        echo Downloading !progName!... >> "%LOG_FILE%"
        REM Extract the file name from the URL
        for %%F in ("!progURL!") do (
            set "fileName=%%~nxF"
        )
        set "downloadFailed=0"
        if exist "!DOWNLOAD_DIR!\!fileName!" (
            echo !fileName! already exists. Skipping download.
            echo !fileName! already exists. Skipping download. >> "%LOG_FILE%"
        ) else (
            s_wget.exe "!progURL!" -O "!DOWNLOAD_DIR!\!fileName!"
            if errorlevel 1 (
                echo Failed to download !progName!.
                echo Failed to download !progName!. >> "%LOG_FILE%"
                set "downloadFailed=1"
            ) else (
                echo !progName! downloaded successfully.
                echo !progName! downloaded successfully. >> "%LOG_FILE%"
            )
        )

        if "!downloadFailed!"=="0" (
            REM Install the program
            echo Installing !progName!...
            echo Installing !progName!... >> "%LOG_FILE%"
            set "installerPath=!DOWNLOAD_DIR!\!fileName!"
            set "installSuccess=0"
            if exist "!installerPath!" (
                REM Determine installer type and run silently
                if /I "!installerPath:~-4!"==".exe" (
                    "!installerPath!" !installSwitches! /norestart /quiet
                    set "cmdErrorLevel=!ERRORLEVEL!"
                ) else if /I "!installerPath:~-4!"==".msi" (
                    msiexec /i "!installerPath!" !installSwitches! /norestart /quiet
                    set "cmdErrorLevel=!ERRORLEVEL!"
                ) else (
                    echo Unknown installer type for !progName!. Cannot install.
                    echo Unknown installer type for !progName!. Cannot install. >> "%LOG_FILE%"
                    set "cmdErrorLevel=1"
                )
                REM Check the error level
                if "!cmdErrorLevel!" EQU "0" (
                    set "installSuccess=1"
                ) else (
                    REM Some installers may return non-zero codes on success
                    REM For certain known installers, we might want to treat specific codes as success
                    REM For now, we'll assume non-zero means failure
                    echo Installer returned error code !cmdErrorLevel!
                    echo Installer returned error code !cmdErrorLevel! >> "%LOG_FILE%"
                )
                if "!installSuccess!"=="1" (
                    echo !progName! installed successfully.
                    echo !progName! installed successfully. >> "%LOG_FILE%"
                ) else (
                    echo Failed to install !progName!.
                    echo Failed to install !progName!. >> "%LOG_FILE%"
                )
            ) else (
                echo Installer for !progName! not found.
                echo Installer for !progName! not found. >> "%LOG_FILE%"
            )
        )
    ) else (
        echo Invalid selection: %%i
        echo Invalid selection: %%i >> "%LOG_FILE%"
    )
)
echo All selected programs have been processed.
echo All selected programs have been processed. >> "%LOG_FILE%"
pause
goto MENU

:ExitScript
echo Exiting.
exit /b 0
