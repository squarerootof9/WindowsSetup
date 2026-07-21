# setup_script.ps1
# Script to set up a Windows environment with various packages.
# Author: threeofthree
# Date: 2024-10-25
# Usage: ./setup_script.ps1
# Note: Must run this script as administrator.
#
# This script is licensed under the MIT License.
# See the LICENSE file in the project root for license information.

# https://github.com/squarerootof9/WindowsSetup?tab=readme-ov-file#setting-the-execution-policy
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Set console encoding to UTF-8 for proper Unicode symbol display
$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding =
New-Object System.Text.UTF8Encoding

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Global Variables
$DOWNLOAD_DIR = Join-Path $env:USERPROFILE "Downloads"
$JAVA_DIR = "C:\JAVA"
$LOG_FILE = Join-Path $DOWNLOAD_DIR "setup_script.log"

#$LINE = "--------------------------------------------"
$LINE = "────────────────────────────────────────────"

function IsAdmin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

If (-not (IsAdmin)) {
    Write-Host "You must run this script as administrator!"
    #Pause
    Exit 1
}

If (-not (Test-Path $LOG_FILE)) {
    New-Item -ItemType File -Path $LOG_FILE | Out-Null
}

function Log($message) {
    $message | Out-File -Append -FilePath $LOG_FILE
}

function PressAnyKey {
    Write-Host "Press any key to continue . . ."
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

function Show-Message {
    param (
        [string]$Message
    )

    # Ensure $Message is set
    if (-not $Message -or $Message -eq "") { $Message = "Message not set" }

    Write-Host ""
    Write-Host $LINE
    Write-Host $Message
    Write-Host $LINE

    # Simulate "Press Any Key to Continue..."
    #Write-Host "`nPress any key to continue..." -NoNewline
    #$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Get-PathFromRegistry {
    Try {
        $pathValue = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment").Path
        return $pathValue
    }
    Catch {
        return $null
    }
}

function Set-PathInRegistry($newPath) {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -Name "Path" -Type ExpandString -Value $newPath
}

function Install-WingetApps {
    param (
        [Parameter(Mandatory)]
        [string[]]$Packages
    )

    foreach ($package in $Packages) {
        winget install `
            --id $package `
            --exact `
            --accept-package-agreements `
            --accept-source-agreements
    }
}

function Remove-WingetApps {
    param (
        [Parameter(Mandatory)]
        [string[]]$Packages
    )

    foreach ($package in $Packages) {
        winget uninstall `
            --id $package `
            --exact `
            --accept-source-agreements
    }
}

function Test-WingetPackageInstalled {
    param (
        [Parameter(Mandatory)]
        [string]$Package
    )

    winget list `
        --id $Package `
        --exact `
        --accept-source-agreements |
    Out-Null

    return ($LASTEXITCODE -eq 0)
}

function Remove-Java_dep {
    Write-Host "Removing Java..."
    Log "Removing Java..."

    # Remove JAVA_HOME
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -Name "JAVA_HOME" -ErrorAction SilentlyContinue

    # Remove Java from PATH
    $currentPath = Get-PathFromRegistry
    If ($null -ne $currentPath) {
        $newPath = $currentPath -replace [Regex]::Escape("$JAVA_DIR\jdk-23.0.1\bin;"), ""
        Set-PathInRegistry $newPath
    }

    # Remove Java directory
    If (Test-Path $JAVA_DIR) {
        Remove-Item -Path $JAVA_DIR -Recurse -Force
    }
    Else {
        Write-Host "Java directory '$JAVA_DIR' does not exist."
        Log "Java directory '$JAVA_DIR' does not exist."
    }

    Write-Host "Java has been removed."
    Log "Java has been removed."
    Write-Host "Please restart your computer or log off and log back in for changes to take effect."
    Log "Please restart your computer or log off and log back in for changes to take effect."
    PressAnyKey
}

function Install-Java_dep {
    Write-Host "Downloading Java..."
    Log "Downloading Java..."

    If (-not (Test-Path $DOWNLOAD_DIR)) {
        New-Item -ItemType Directory -Path $DOWNLOAD_DIR | Out-Null
    }

    $DOWNLOAD_URL = "https://download.java.net/java/GA/jdk23.0.1/c28985cbf10d4e648e4004050f8781aa/11/GPL/openjdk-23.0.1_windows-x64_bin.zip"
    $javaZip = Join-Path $DOWNLOAD_DIR "openjdk-23.0.1_windows-x64_bin.zip"

    Try {
        Invoke-WebRequest $DOWNLOAD_URL -OutFile $javaZip
    }
    Catch {
        Write-Host "Failed to download Java."
        Log "Failed to download Java."
        PressAnyKey
        return
    }

    If (-not (Test-Path $JAVA_DIR)) {
        New-Item -ItemType Directory -Path $JAVA_DIR | Out-Null
    }

    Write-Host "Extracting Java..."
    Log "Extracting Java..."

    Try {
        Expand-Archive -Path $javaZip -DestinationPath $JAVA_DIR -Force
    }
    Catch {
        Write-Host "Failed to extract Java."
        Log "Failed to extract Java."
        PressAnyKey
        return
    }

    $currentPath = Get-PathFromRegistry
    $newPath = $currentPath + ";" + "$JAVA_DIR\jdk-23.0.1\bin"
    Set-PathInRegistry $newPath

    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -Name "JAVA_HOME" -Value "$JAVA_DIR\jdk-23.0.1"

    Write-Host "Java has been installed and environment variables have been updated."
    Log "Java has been installed and environment variables have been updated."
    Write-Host "Please restart your computer or log off and log back in for changes to take effect."
    Log "Please restart your computer or log off and log back in for changes to take effect."
    PressAnyKey
}

$JAVA_PACKAGE = "EclipseAdoptium.Temurin.21.JDK"

function Install-Java {
    Write-Host "Installing Java..." -ForegroundColor Cyan
    Log "Installing Java package: $JAVA_PACKAGE"

    Install-WingetApps -Packages $JAVA_PACKAGE

    Write-Host ""
    java -version

    Write-Host "$([char]0x2705) Java has been installed." -ForegroundColor Green
    Log "Java has been installed."

    
}

function Remove-Java {
    Write-Host "Removing Java..." -ForegroundColor Cyan
    Log "Removing Java package: $JAVA_PACKAGE"

    Remove-WingetApps -Packages $JAVA_PACKAGE

    Write-Host "$([char]0x274C) Java has been removed." -ForegroundColor Red
    Log "Java has been removed."

    
}
function AddOrRemoveJava {
    # Check if Java is installed
    #$javaInstalled = $false
    #Try {
    #java -version > $null 2>&1
    #If ($LASTEXITCODE -eq 0) {
    #$javaInstalled = $true
    #}
    #}
    #Catch {
    #$javaInstalled = $false
    #}

    $javaInstalled = Test-WingetPackageInstalled -Package $JAVA_PACKAGE

    If ($javaInstalled) {
        Write-Host "Java is currently installed."
        $removeJava = Read-Host "Do you want to remove Java? (y/N)"
        If ($removeJava -match '^[Yy]$') {
            Remove-Java
        }
    }
    Else {
        Write-Host "Java is not installed."
        $installJava = Read-Host "Do you want to install Java? (y/N)"
        If ($installJava -match '^[Yy]$') {
            Install-Java
        }
    }
}

function LoadPrograms {
    If (-not (Test-Path "app_list.txt")) {
        Write-Host "Error: app_list.txt not found."
        Log "Error: app_list.txt not found."
        
        return $null
    }

    $lines = Get-Content "app_list.txt"
    $programs = New-Object System.Collections.ArrayList

    ForEach ($line in $lines) {
        $line = $line.Trim()
        If ([string]::IsNullOrEmpty($line)) { continue }
        If ($line.StartsWith("#")) { continue }

        # Format: ProgramName|DownloadURL|InstallSwitches
        $parts = $line.Split('|')
        If ($parts.Count -ge 2) {
            $progName = $parts[0].Trim()
            $progURL = $parts[1].Trim()
            $installSwitches = ""
            If ($parts.Count -ge 3) {
                $installSwitches = $parts[2].Trim()
            }
            $null = $programs.Add([PSCustomObject]@{
                    Name     = $progName
                    URL      = $progURL
                    Switches = $installSwitches
                })
        }
    }

    If ($programs.Count -eq 0) {
        Write-Host "No programs found in app_list.txt."
        Log "No programs found in app_list.txt."
        
        return $null
    }

    return $programs
}

function firefox {

    ### FIREFOX-START

    Install-WingetApps -Packages "Mozilla.Firefox"

    Write-Host "Disabling Firefox automatic startup..."

    $firefoxStartupEntries = Get-ItemProperty `
        -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" `
        -ErrorAction SilentlyContinue

    $firefoxStartupEntries.PSObject.Properties |
    Where-Object {
        $_.Name -like "Mozilla-Firefox-*" -or
        [string]$_.Value -match '\\firefox\.exe.*-os-autostart'
    } |
    ForEach-Object {
        Remove-ItemProperty `
            -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" `
            -Name $_.Name `
            -Force
    }

    ### FIREFOX-END
}

function Disable-EdgeBackground {
    Write-Host "Removing Microsoft Edge shortcuts..." `
        -ForegroundColor Cyan

    Remove-Item `
        "$env:PUBLIC\Desktop\Microsoft Edge.lnk" `
        -Force `
        -ErrorAction SilentlyContinue

    Remove-Item `
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" `
        -Force `
        -ErrorAction SilentlyContinue

    Write-Host "Disabling Microsoft Edge background startup..." `
        -ForegroundColor Cyan

    $edgePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

    New-Item -Path $edgePolicy -Force | Out-Null

    Set-ItemProperty `
        -Path $edgePolicy `
        -Name "StartupBoostEnabled" `
        -Type DWord `
        -Value 0 `
        -Force

    Set-ItemProperty `
        -Path $edgePolicy `
        -Name "BackgroundModeEnabled" `
        -Type DWord `
        -Value 0 `
        -Force

    Write-Host ""
    Write-Host "✓ Microsoft Edge background activity has been disabled." `
        -ForegroundColor Green
}

$CORE_PROGRAMS = @(
    "VideoLAN.VLC"
    "Audacity.Audacity"
    "Geany.Geany"
    "Upscayl.Upscayl"
    "OBSProject.OBSStudio"
    "OpenSC.OpenSC"
    "ChristianHohnstadt.xca"
    "GnuPG.Gpg4win"
    "Git.Git"
    "Python.Python.3.14"
    "WireGuard.WireGuard"
    "TigerVNC.TigerVNC"
    "KDE.KDEConnect.AppX"
    "DBBrowserForSQLite.DBBrowserForSQLite"
    "Microsoft.Sysinternals.Whois"
    "DiskInternals.LinuxReader"
    "Microsoft.WSL"
)

$OTHER_PROGRAMS = @(
    "OpenShot.OpenShot"
    "BlenderFoundation.Blender"
    "GIMP.GIMP"
    "Inkscape.Inkscape"
    "FreeCAD.FreeCAD"
    "Flashforge.Orca-Flashforge"
    "RaspberryPiFoundation.RaspberryPiImager"
)

$MORE_PROGRAMS = @(
    "Balena.Etcher"
    "IDRIX.VeraCrypt" 
    "TheDocumentFoundation.LibreOffice"
)

$DEV_PROGRAMS = @(
    "Google.AndroidStudio"
    "Microsoft.VisualStudioCode"
    "JetBrains.IntelliJIDEA.Community"
    "JetBrains.WebStorm"
    "ArduinoSA.IDE.stable"
    "gnome.Glade"
    "Google.DartSDK"
    "KiCad.KiCad" # 921MB
    "ShiningLight.OpenSSL.Dev" #
)

$ALL_PROGRAMS = $CORE_PROGRAMS + $OTHER_PROGRAMS + $MORE_PROGRAMS + $DEV_PROGRAMS

#ALL_PROGRAMS = $CORE_PROGRAMS + $OTHER_PROGRAMS

function AddBasePrograms {

    $count = $CORE_PROGRAMS.Count
    Write-Host "This process will download and install $count programs."
    Write-Host "This may take a significant amount of time."
    $proceed = Read-Host "Do you wish to continue? (y/n)"
    If ($proceed -notmatch '^[Yy]$') {
        Write-Host "Operation cancelled."
        return
    }
    
    foreach ($package in $CORE_PROGRAMS) {
        Install-WingetApps -Packages $package
    }

}

function AddAllPrograms {

    $count = $ALL_PROGRAMS.Count
    Write-Host "This process will download and install all $count programs."
    Write-Host "This may take a significant amount of time."
    $proceed = Read-Host "Do you wish to continue? (y/n)"
    If ($proceed -notmatch '^[Yy]$') {
        Write-Host "Operation cancelled."
        return
    }

    firefox
    
    foreach ($package in $ALL_PROGRAMS) {
        Install-WingetApps -Packages $package
    }
    
    Install-VSCodeExtensions

}
function AddAllPrograms_old {
    $programs = LoadPrograms
    If ($null -eq $programs) { return }

    $count = $programs.Count
    Write-Host "This process will download and install all $count programs."
    Write-Host "This may take a significant amount of time."
    $proceed = Read-Host "Do you wish to continue? (y/n)"
    If ($proceed -notmatch '^[Yy]$') {
        Write-Host "Operation cancelled."
        return
    }

    # Build a list of all program indices
    $selectedIndices = 1..$count

    ProcessSelectedPrograms $programs $selectedIndices
}

function AddIndividualPrograms {
    $programs = $ALL_PROGRAMS
    If ($null -eq $programs) { return }

    Write-Host "Available Programs:"
    Log "Available Programs:"
    for ($i = 0; $i -lt $programs.Count; $i++) {
        $idx = $i + 1
        Write-Host "$idx) $($programs[$i])"
        Log "$idx) $($programs[$i])"
    }

    Write-Host "0) Exit"
    Log "0) Exit"
    Write-Host
    $selected = Read-Host "Enter the numbers of the programs to download and install, separated by commas (e.g., 1,3,5):"

    $selectedIndices = ($selected -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }

    If ($selectedIndices -contains '0') {
        return
    }

    foreach ($selectedIndex in $selectedIndices) {
        $arrayIndex = [int]$selectedIndex - 1

        if ($arrayIndex -lt 0 -or $arrayIndex -ge $programs.Count) {
            Write-Host "Invalid selection: $selectedIndex" `
                -ForegroundColor Yellow
            continue
        }

        Install-WingetApps -Packages $programs[$arrayIndex]
    }

    #ProcessSelectedPrograms $programs $selectedIndices
}

function Install-VSCodeExtensions {

    $extensionFile = Join-Path $PSScriptRoot "vscode-extensions.txt"

    If (-not (Test-Path $extensionFile)) {
        Write-Host "Extension list not found: $extensionFile" `
            -ForegroundColor Red
        return
    }
    
    Write-Host "➜ Adding VS Code extensions…"

    #This only hides the warning; the actual repair must come from Microsoft replacing the deprecated url.parse() call.
    #Node documents DEP0169
    $oldNodeOptions = $env:NODE_OPTIONS
    $env:NODE_OPTIONS = "--no-deprecation"

    try {
        Get-Content (Join-Path $PSScriptRoot "vscode-extensions.txt") |
        ForEach-Object {
            $ext = $_.Trim()

            if (
                -not [string]::IsNullOrWhiteSpace($ext) -and
                -not $ext.StartsWith("#")
            ) {
                code --install-extension $ext
            }
        }
    }
    finally {
        $env:NODE_OPTIONS = $oldNodeOptions
    }

    Write-Host "✓ VS Code extensions added." `
        -ForegroundColor Green
}

function Install-VSCodeExtensions_old {
    $extensionFile = Join-Path $PSScriptRoot "vscode-extensions.txt"

    If (-not (Test-Path $extensionFile)) {
        Write-Host "Extension list not found: $extensionFile" `
            -ForegroundColor Red
        return
    }

    Write-Host "➜ Adding VS Code extensions…"

    Get-Content $extensionFile | ForEach-Object {
        $ext = $_.Trim()

        If ([string]::IsNullOrWhiteSpace($ext)) {
            return
        }

        If ($ext.StartsWith("#")) {
            return
        }

        code --install-extension $ext
    }

    Write-Host "✓ VS Code extensions added." `
        -ForegroundColor Green
}

function ProcessSelectedPrograms($programs, $selectedIndices) {
    If (-not (Test-Path $DOWNLOAD_DIR)) {
        New-Item -ItemType Directory -Path $DOWNLOAD_DIR | Out-Null
    }

    ForEach ($idx in $selectedIndices) {
        $intIdx = [int]$idx
        If ($intIdx -lt 1 -or $intIdx -gt $programs.Count) {
            Write-Host "Invalid selection: $idx"
            Log "Invalid selection: $idx"
            continue
        }

        $prog = $programs[$intIdx - 1]
        Write-Host "Processing $($prog.Name)..."
        Log "Processing $($prog.Name)..."

        Write-Host "Downloading $($prog.Name)..."
        Log "Downloading $($prog.Name)..."
        $fileName = [System.IO.Path]::GetFileName($prog.URL)
        $installerPath = Join-Path $DOWNLOAD_DIR $fileName

        If (Test-Path $installerPath) {
            Write-Host "$fileName already exists. Skipping download."
            Log "$fileName already exists. Skipping download."
        }
        Else {
            Try {
                Invoke-WebRequest $prog.URL -OutFile $installerPath
                Write-Host "$($prog.Name) downloaded successfully."
                Log "$($prog.Name) downloaded successfully."
            }
            Catch {
                Write-Host "Failed to download $($prog.Name)."
                Log "Failed to download $($prog.Name)."
                continue
            }
        }

        Write-Host "Installing $($prog.Name)..."
        Log "Installing $($prog.Name)..."
        $installSuccess = $false
        If (Test-Path $installerPath) {
            $ext = [System.IO.Path]::GetExtension($installerPath).ToLower()
            $processExitCode = $null
            Try {
                If ($ext -eq ".exe") {
                    $process = Start-Process $installerPath -ArgumentList $prog.Switches, "/norestart", "/quiet" -Wait -PassThru
                    $processExitCode = $process.ExitCode
                }
                ElseIf ($ext -eq ".msi") {
                    $process = Start-Process "msiexec" -ArgumentList "/i", $installerPath, $prog.Switches, "/norestart", "/quiet" -Wait -PassThru
                    $processExitCode = $process.ExitCode
                }
                Else {
                    Write-Host "Unknown installer type for $($prog.Name). Cannot install."
                    Log "Unknown installer type for $($prog.Name). Cannot install."
                    continue
                }

                If ($processExitCode -eq 0) {
                    $installSuccess = $true
                }
                Else {
                    Write-Host "Installer returned error code $processExitCode"
                    Log "Installer returned error code $processExitCode"
                }
            }
            Catch {
                Write-Host "Error running installer for $($prog.Name): $($_.Exception.Message)"
                Log "Error running installer for $($prog.Name): $($_.Exception.Message)"
            }

            If ($installSuccess) {
                Write-Host "$($prog.Name) installed successfully."
                Log "$($prog.Name) installed successfully."
            }
            Else {
                Write-Host "Failed to install $($prog.Name)."
                Log "Failed to install $($prog.Name)."
            }
        }
        Else {
            Write-Host "Installer for $($prog.Name) not found."
            Log "Installer for $($prog.Name) not found."
        }
    }

    Log "All selected programs have been processed."
    Show-Message "All selected programs have been processed."

}

function ApplySettings {

    Write-Host $LINE
    Write-Host "Applying Registry Settings..."
    Write-Host $LINE

    ####
    ## Personalization
    ####

    # Personalization > Taskbar > Search
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type DWord -Value 3

    # Personalization > Taskbar > Task view
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value 0

    # Personalization > Taskbar > Widgets
    #Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Type DWord -Value 0

    # Personalization > Taskbar > Other system tray icons > Task Manager
    # Set-ItemProperty -Path "HKCU:\Control Panel\NotifyIconSettings\10659982090346756599" -Name "IsPromoted" -Type DWord -Value 1

    ####
    ## Accessibility
    ####

    # Accessibility > Visual effects > Always show scrollbars
    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility" -Name "DynamicScrollbars" -Type DWord -Value 0

    Write-Host "Personalization > Taskbar and Accessibility settings have been applied."

    ####
    ## Privacy & Security
    ####

    # Privacy & Security > General

    # Disable "Let apps show me personalized ads by using my advertising ID"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Type DWord -Value 0

    # Disable "Let websites show me locally relevant content by accessing my language list"
    Set-ItemProperty -Path "HKCU:\Control Panel\International\User Profile" -Name "HttpAcceptLanguageOptOut" -Type DWord -Value 1

    # Disable "Let Windows improve Start and search results by tracking app launches"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Type DWord -Value 0

    # Disable "Show me suggested content in the Settings app"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338393Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353694Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353696Enabled" -Type DWord -Value 0

    # Disable "Show me notifications in Settings app"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications" -Name "EnableAccountNotifications" -Type DWord -Value 0

    Write-Host "Privacy & Security > General settings have been applied."

    # Privacy & Security: Disable "Inking & Typing Personalization"

    #Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CPSS\Store\InkingAndTypingPersonalization\Value" -Name "Value" -Value 0 -Type DWord -Force
    #Set-ItemProperty -Path "HKCU:\Software\Microsoft\Personalization\Settings\AcceptedPrivacyPolicy" -Name "AcceptedPrivacyPolicy" -Value 0 -Type DWord -Force
    #Set-ItemProperty -Path "HKCU:\Software\Microsoft\Personalization\Settings\AcceptedPrivacyPolicy" -Name "AcceptedPrivacyPolicy" -Value 0 -Type DWord -Force
    #Set-ItemProperty -Path "HKCU:\Software\Microsoft\InputPersonalization\RestrictImplicitTextCollection" -Name "RestrictImplicitTextCollection" -Value 1 -Type DWord -Force
    #Set-ItemProperty -Path "HKCU:\Software\Microsoft\InputPersonalization\RestrictImplicitInkCollection" -Name "RestrictImplicitInkCollection" -Value 1 -Type DWord -Force
    #Set-ItemProperty -Path "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore\HarvestContacts" -Name "HarvestContacts" -Value 0 -Type DWord -Force

    Write-Host "Inking & Typing Personalization settings updated successfully."

    # Privacy & Security: Disable Diagnostic Data Toast Notification
    # Path: HKCU\Software\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack
    # Key: ShowedToastAtLevel (DWORD) | 1 = Suppress notifications about diagnostic data
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" -Name "ShowedToastAtLevel" -Value 1 -Type DWord -Force

    # Privacy & Security: Disable "Improve Inking and Typing"
    # Path: HKCU\Software\Microsoft\input\TIPC
    # Key: Enabled (DWORD) | 0 = Off (Disable collection of typing & handwriting data)
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\input\TIPC" -Name "Enabled" -Value 0 -Type DWord -Force

    # Privacy & Security: Disable "Tailored Experience with Diagnostic Data"
    # Path: HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy
    # Key: TailoredExperiencesWithDiagnosticDataEnabled (DWORD) | 0 = Off (Prevents personalization based on diagnostic data)
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0 -Type DWord -Force

    # Confirmation message

    Write-Host "Privacy settings updated successfully."

    #### TODO: edit below for neatness and proper order

    # Enable long paths
    Write-Host "Enabling long paths..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -Type DWord -Force

    # Show seconds in system clock
    Write-Host "Showing seconds in system clock..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSecondsInSystemClock" -Value 1 -Type DWord -Force

    # Set timezone
    Write-Host "Setting timezone..."
    tzutil /s "Eastern Standard Time"

    Write-Host "Setting Realtime to Universal (BIOS should be set to GMT/UTC)..."
    reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_DWORD /d 1 /f

    # Show file extensions
    Write-Host "Setting file extensions to be visible..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -Force

    # Taskview to on
    Write-Host "Enabling Task View on the taskbar..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value 1 -Force

    # Emoji Panel to always on
    Write-Host "Setting Emoji and more icon to Always..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\TabletTip\1.7" -Name "EmojiAndMoreIconVisibilityState" -Type DWord -Value 2 -Force

    # Set Windows and App mode to Dark
    Write-Host "Setting Windows and App mode to Dark..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord -Force

    # Ensure modern shell settings are enabled (disables classic shell behavior)
    Write-Host "Ensuring modern shell settings are enabled..."
    # Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "ClassicShell" -Value 0 -Type DWord -Force

    # https://www.elevenforum.com/t/open-item-with-single-click-or-double-click-in-windows-11.6122/
    # Enable single-click to open items
    Write-Host "Enabling single-click to open items..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "IconUnderline" -Value 2 -Type DWord -Force

    Write-Host "Updating ShellState using reg.exe..."
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v ShellState /t REG_BINARY /d 240000001ea8000000000000000000000000000001000000130000000000000062000000 /f

    # Ensure icons are underlined when hovering
    Write-Host "Ensuring icons are underlined when hovering..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Internet Explorer\Main" -Name "Anchor Underline" -Value "yes" -Type String -Force

    # Power mode plugged in to best performance
    #Write-Host "Setting plugged-in power mode to Best performance..."
    #Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes" -Name "ActiveOverlayAcPowerScheme" -Type String -Value "ded574b5-45a0-4f42-8737-46345c09c238" -Force

    Write-Host "Registry changes applied successfully."

    # Restart Explorer to apply changes
    Write-Host "Restarting Explorer to apply changes..."
    Stop-Process -Name explorer -Force
    Start-Process explorer

    Show-Message "Registry settings applied."

}

function WindowsFeatures {

    $features = @("Printing-XPSServices-Features", "TelnetClient")

    Write-Host ""

    foreach ($feature in $features) {
        Write-Host "Installing $feature..."
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
    }

    Show-Message("All selected features have been installed.")

}

function DisableOneDrive {

    Write-Host ""
    Write-Host "Disabling OneDrive..."

    # Stop OneDrive if running
    if (Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue) {
        Write-Host "Stopping OneDrive..."
        Stop-Process -Name "OneDrive" -Force
    }
    else {
        Write-Host "OneDrive process not found. Skipping stop."
    }

    # Disable OneDrive startup and integration
    Write-Host "Disabling OneDrive startup..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -Value "" -Type String -Force
    # Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1 -Type DWord -Force

    # Uninstall OneDrive
    $oneDrivePaths = @(
        "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
        "$env:SystemRoot\System32\OneDriveSetup.exe"
    )

    $uninstalled = $false
    foreach ($path in $oneDrivePaths) {
        if (Test-Path $path) {
            Write-Host "Uninstalling OneDrive..."
            Start-Process -FilePath $path -ArgumentList "/uninstall" -NoNewWindow -Wait
            $uninstalled = $true
            break
        }
    }

    if (-not $uninstalled) {
        Write-Host "ERROR: OneDriveSetup.exe not found. Skipping uninstall."
    }

    # Restart Explorer to apply changes
    Write-Host "Restarting Explorer..."
    Stop-Process -Name explorer -Force
    Start-Process explorer

    Show-Message "OneDrive has been disabled."

}

function ManageSSHD {

    # Prompt the user for action
    $choice = (Read-Host "Do you want to (i)nstall or (u)ninstall OpenSSH-Server? [i/u]").Trim()

    if ($choice -ieq "I") {
        Write-Host "Installing and configuring OpenSSH-Server..." -ForegroundColor Cyan

        #Add-WindowsFeature -Name "OpenSSH-Server"
        #Enable-WindowsOptionalFeature -Online -FeatureName "OpenSSH-Server" -All -NoRestart
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

        #Set-Service -Name ssh-agent -StartupType Automatic
        Set-Service -Name sshd -StartupType Automatic

        Start-Service sshd

        Remove-NetFirewallRule `
            -DisplayName "OpenSSH-Server" `
            -ErrorAction SilentlyContinue

        New-NetFirewallRule `
            -DisplayName "OpenSSH-Server" `
            -Direction Inbound `
            -LocalPort 22 `
            -Action Allow `
            -Protocol TCP | Out-Null

        # Prompt the user for action
        $shellChoice = (Read-Host "Do you want to use Windows PowerShell 5.1 over SSH? [y/n]").Trim()

        # "C:\Program Files\PowerShell\7\pwsh.exe"
        if ($shellChoice -ieq "Y") {
            New-ItemProperty `
                -Path "HKLM:\SOFTWARE\OpenSSH" `
                -Name "DefaultShell" `
                -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
                -PropertyType String `
                -Force
        }

        Restart-Service sshd

        #$myIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" }).IPAddress
        $myIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -match "^Ethernet|^Wi-Fi|^wlan|^eth" }).IPAddress

        Get-Service -Name *ssh*

        Write-Host "$([char]0x2705) OpenSSH-Server has been started." -ForegroundColor Green
        Write-Host "$([char]0x2705) Firewall Rule (OpenSSH-Server) has been added for port 22 (TCP)." -ForegroundColor Green
        Write-Host "$([char]0x2705) SSH Daemon (OpenSSH-Server) is set to start automatically." -ForegroundColor Green
        Write-Host ""
        Write-Host "$([char]0x2139)  You can change its startup type in 'Services' under 'OpenSSH-Server' or"
        Write-Host " by running this script again and selecting Uninstall."
        Write-Host ""
        Write-Host "$([char]0x1055) connect at: $myIP" -ForegroundColor Blue

    }
    elseif ($choice -ieq "U") {
        Write-Host "Uninstalling OpenSSH-Server configuration..." -ForegroundColor Cyan

        Stop-Service sshd -ErrorAction SilentlyContinue
        Set-Service -Name sshd -StartupType Disabled

        Remove-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

        Remove-NetFirewallRule `
            -DisplayName "OpenSSH-Server" `
            -ErrorAction SilentlyContinue

        Remove-ItemProperty `
            -Path "HKLM:\SOFTWARE\OpenSSH" `
            -Name "DefaultShell" `
            -ErrorAction SilentlyContinue

        Get-WindowsCapability -Online | Where-Object Name -like "OpenSSH.Server*"
        Write-Host "$([char]0x274C) You must reboot to complete removal!" -ForegroundColor Red
        Write-Host "$([char]0x274C) OpenSSH-Server has been stopped and disabled." -ForegroundColor Red
        Write-Host "$([char]0x274C) Firewall rule (OpenSSH-Server) has been removed." -ForegroundColor Red
        Write-Host "$([char]0x2139)  If you need OpenSSH-Server again, rerun this script and choose Install." -ForegroundColor Yellow
        Write-Host ""
    }
    else {
        Write-Host "Invalid choice. Please run the script again and select (i)nstall or (u)ninstall." -ForegroundColor Yellow
    }

    

}

function ManageRDP {

    $RuleTcp3389 = "SetupScript-RDP-TCP-3389"
    $RuleUdp3389 = "SetupScript-RDP-UDP-3389"

    $FirewallProfiles = "Private,Domain"

    $choice = (Read-Host "Do you want to (e)nable or (d)isable Remote Desktop? [e/d]").Trim()

    if ($choice -ieq "E") {
        Write-Host "Enabling Remote Desktop..." -ForegroundColor Cyan

        try {
            # Allow incoming Remote Desktop connections
            Set-ItemProperty `
                -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" `
                -Name "fDenyTSConnections" `
                -Type DWord `
                -Value 0

            # Require Network Level Authentication
            Set-ItemProperty `
                -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
                -Name "UserAuthentication" `
                -Type DWord `
                -Value 1

            # TermService normally uses Manual/triggered startup
            Set-Service -Name "TermService" -StartupType Manual

            if ((Get-Service -Name "TermService").Status -ne "Running") {
                Start-Service -Name "TermService"
            }

            # Remove our existing rules first, making this idempotent
            Remove-NetFirewallRule -DisplayName $RuleTcp3389 -ErrorAction SilentlyContinue
            Remove-NetFirewallRule -DisplayName $RuleUdp3389 -ErrorAction SilentlyContinue

            New-NetFirewallRule `
                -DisplayName $RuleTcp3389 `
                -Description "Remote Desktop TCP traffic" `
                -Direction Inbound `
                -Action Allow `
                -Protocol TCP `
                -LocalPort 3389 `
                -Profile $FirewallProfiles | Out-Null

            New-NetFirewallRule `
                -DisplayName $RuleUdp3389 `
                -Description "Remote Desktop UDP traffic" `
                -Direction Inbound `
                -Action Allow `
                -Protocol UDP `
                -LocalPort 3389 `
                -Profile $FirewallProfiles | Out-Null

            $ipAddresses = Get-NetIPAddress -AddressFamily IPv4 |
            Where-Object {
                $_.IPAddress -notlike "127.*" -and
                $_.IPAddress -notlike "169.254.*"
            } |
            Select-Object -ExpandProperty IPAddress

            Write-Host ""
            Write-Host "$([char]0x2705) Remote Desktop has been enabled." -ForegroundColor Green
            Write-Host "$([char]0x2705) Network Level Authentication is enabled." -ForegroundColor Green
            Write-Host "$([char]0x2705) Remote Desktop Services is running." -ForegroundColor Green
            Write-Host "$([char]0x2705) Firewall rules were added:" -ForegroundColor Green
            Write-Host "    $RuleTcp3389"
            Write-Host "    $RuleUdp3389"

            if ($ipAddresses) {
                Write-Host ""
                Write-Host "Connect using:" -ForegroundColor Blue

                foreach ($ipAddress in $ipAddresses) {
                    Write-Host "    mstsc /v:$ipAddress"
                }
            }
        }
        catch {
            Write-Host ""
            Write-Host "Failed to enable Remote Desktop:" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
    elseif ($choice -ieq "D") {
        Write-Host "Disabling Remote Desktop..." -ForegroundColor Cyan

        try {
            # Reject incoming Remote Desktop connections
            Set-ItemProperty `
                -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" `
                -Name "fDenyTSConnections" `
                -Type DWord `
                -Value 1

            # Remove only the rules created by this function
            Remove-NetFirewallRule -DisplayName $RuleTcp3389 -ErrorAction SilentlyContinue
            Remove-NetFirewallRule -DisplayName $RuleUdp3389 -ErrorAction SilentlyContinue

            Stop-Service -Name "TermService" -Force -ErrorAction SilentlyContinue

            Write-Host ""
            Write-Host "$([char]0x274C) Remote Desktop has been disabled." -ForegroundColor Red
            Write-Host "$([char]0x274C) Remote Desktop Services has been stopped." -ForegroundColor Red
            Write-Host "$([char]0x274C) Setup Script RDP firewall rules were removed." -ForegroundColor Red
        }
        catch {
            Write-Host ""
            Write-Host "Failed to disable Remote Desktop:" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
    else {
        Write-Host "Invalid choice. Select (e)nable or (d)isable." -ForegroundColor Yellow
    }

    Write-Host ""
    Get-Service -Name "TermService" |
    Format-Table Status, StartType, Name, DisplayName -AutoSize

    
}

#####
#DNS#
#####

function ManageDNS() {
    # Prompt the user for action
    $choice = (Read-Host "Do you want to (e)nable or (r)emove CloudFlare/Quad9 TLS DNS? [e/r]").Trim()

    if ($choice -ieq "E") {
        Enable-StealthDns
    }
    elseif ($choice -ieq "R") {
        Disable-StealthDns
    }
    else {
        Write-Host "Invalid choice. Please run the script again and select (e)nable or (r)emove." -ForegroundColor Yellow
    }

    
}

<#
   Stealth DNS (Windows 11)
   Cloudflare + Quad9 over DoH, no plaintext fallback.
   Run in an elevated PowerShell session.
#>

#-----------------------------
# Common settings
#-----------------------------
# IPv4 (you've been using this combo already)
$StealthDnsV4 = @(
    '1.1.1.1',   # Cloudflare
    '9.9.9.9'    # Quad9
)

# Optional IPv6 (uncomment if you want v6 too)
$StealthDnsV6 = @(
    '2606:4700:4700::1111', # Cloudflare
    '2620:fe::fe'           # Quad9
)

# DoH templates from providers
# (Windows associates an IP with a DoH template and flags for upgrade/fallback) :contentReference[oaicite:1]{index=1}
$DoHServers = @(
    @{ IP = '1.1.1.1'; Template = 'https://cloudflare-dns.com/dns-query' },
    @{ IP = '1.0.0.1'; Template = 'https://cloudflare-dns.com/dns-query' },
    @{ IP = '9.9.9.9'; Template = 'https://dns.quad9.net/dns-query' },
    @{ IP = '149.112.112.112'; Template = 'https://dns.quad9.net/dns-query' }
)

#-----------------------------
# Helper: get "real" interfaces
#-----------------------------
function Get-StealthDnsTargets {
    # Use NetIPConfiguration so we only touch interfaces that actually route traffic
    # (have a default gateway). 
    Get-NetIPConfiguration |
    Where-Object {
        $_.NetAdapter.Status -eq 'Up' -and
        ($_.IPv4DefaultGateway -or $_.IPv6DefaultGateway)
    }
}

function GetDns() { 
    Write-Host "Current DoH configuration:" -ForegroundColor DarkCyan
    try {
        Get-DnsClientDohServerAddress | Format-Table -AutoSize
    }
    catch {
        Write-Host "  (Get-DnsClientDohServerAddress not available on this build?)"
    }

    Write-Host "You can also run:  netsh dns show encryption" -ForegroundColor DarkGray
}

#-----------------------------
# Enable Stealth DNS (install)
#-----------------------------
function Enable-StealthDns {
    Write-Host "Enabling Stealth DNS (Cloudflare + Quad9 over DoH)..." -ForegroundColor Cyan

    # 1) Make sure DoH templates exist + are "encrypted only, no fallback"
    foreach ($s in $DoHServers) {
        try {
            # Try to add first (no-op if it already exists with same settings) :contentReference[oaicite:3]{index=3}
            Add-DnsClientDohServerAddress `
                -ServerAddress     $s.IP `
                -DohTemplate       $s.Template `
                -AllowFallbackToUdp $false `
                -AutoUpgrade        $true `
                -ErrorAction Stop | Out-Null

            Write-Host "Added DoH server $($s.IP) ($($s.Template))"
        }
        catch {
            # If it already exists, tighten its settings
            try {
                Set-DnsClientDohServerAddress `
                    -ServerAddress      $s.IP `
                    -DohTemplate        $s.Template `
                    -AllowFallbackToUdp $false `
                    -AutoUpgrade        $true `
                    -ErrorAction Stop | Out-Null

                Write-Host "Updated DoH server $($s.IP) (auto-upgrade + no UDP fallback)"
            }
            catch {
                Write-Warning "Could not configure DoH for $($s.IP): $($_.Exception.Message)"
            }
        }
    }

    # 2) Apply DNS servers to active routed interfaces
    $targets = Get-StealthDnsTargets
    if (-not $targets) {
        Write-Warning "No active routed interfaces found. Nothing to configure."
        return
    }

    $allDns = @()
    $allDns += $StealthDnsV4
    if ($StealthDnsV6.Count -gt 0) {
        $allDns += $StealthDnsV6
    }

    foreach ($cfg in $targets) {
        $idx = $cfg.InterfaceIndex
        $name = $cfg.InterfaceAlias

        Write-Host "Setting DNS on [$name] (InterfaceIndex $idx) -> $($allDns -join ', ')"

        try {
            Set-DnsClientServerAddress `
                -InterfaceIndex $idx `
                -ServerAddresses $allDns `
                -ErrorAction Stop

            Write-Host "DNS set on $name"
        }
        catch {
            Write-Warning "Failed to set DNS on ${name}: $($_.Exception.Message)"
        }
    }

    Enable-StealthDnsInterface

    GetDns

}
#https://learn.microsoft.com/en-us/powershell/module/dnsclient/?view=windowsserver2025-ps
function Enable-StealthDnsInterface() {

    #    Clear-DnsClientCache
    # Run in an elevated PowerShell (Admin)
    # Run as Administrator
    # Run as Administrator

    # map IP -> template + flag byte (from your export)
    $profiles = @{
        '1.1.1.1'              = @{ Template = 'https://one.one.one.one/dns-query'; Flag = 0x11 }
        '9.9.9.9'              = @{ Template = 'https://dns.quad9.net/dns-query'; Flag = 0x02 }
        '2606:4700:4700::1111' = @{ Template = 'https://cloudflare-dns.com/dns-query'; Flag = 0x11 }
        '2620:fe::fe'          = @{ Template = 'https://dns.quad9.net/dns-query'; Flag = 0x02 }
    }

    Get-NetAdapter |
    Where-Object { $_.Status -eq 'Up' } |
    ForEach-Object {
        $guid = $_.InterfaceGuid

        foreach ($ip in $profiles.Keys) {
            $p = $profiles[$ip]
            $isV6 = $ip -like '*:*'
            $leaf = if ($isV6) { 'Doh6' } else { 'Doh' }

            $path = "HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\${guid}"

            New-ItemProperty -Path $path -Name 'NameServer' `
                -PropertyType String -Value "2606:4700:4700::1111,2620:fe::fe" -Force | Out-Null

            $path = "HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\${guid}"

            New-ItemProperty -Path $path -Name 'ProfileNameServer' `
                -PropertyType String -Value "1.1.1.1,9.9.9.9" -Force | Out-Null

            $path = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\${guid}\DohProfileSettings\$leaf\$ip"
            Write-Host $path
            if (-not (Test-Path $path)) {
                New-Item -Path $path -Force | Out-Null
            }

            New-ItemProperty -Path $path -Name 'DohTemplate' `
                -PropertyType String -Value $p.Template -Force | Out-Null

            New-ItemProperty -Path $path -Name 'DohFlags' `
                -PropertyType Binary -Value ([byte[]]@($p.Flag, 0, 0, 0, 0, 0, 0, 0)) -Force | Out-Null
        }
    }

}

#-----------------------------
# Disable / reset Stealth DNS
#-----------------------------
function Disable-StealthDns {
    Write-Host "Disabling Stealth DNS and resetting DNS to DHCP defaults..." -ForegroundColor Yellow

    $targets = Get-StealthDnsTargets
    if ($targets) {
        foreach ($cfg in $targets) {
            $idx = $cfg.InterfaceIndex
            $name = $cfg.InterfaceAlias

            Write-Host "Resetting DNS on [$name] (InterfaceIndex $idx)..."
            try {
                Set-DnsClientServerAddress -InterfaceIndex $idx -ResetServerAddresses -ErrorAction Stop
                Write-Host "DNS reset on $name"
            }
            catch {
                Write-Warning "Failed to reset DNS on ${name}: $($_.Exception.Message)"
            }
        }
    }

    # Optional: clean up DoH entries for Cloudflare + Quad9
    $toRemove = $DoHServers.IP
    Write-Host "Removing DoH templates for: $($toRemove -join ', ')"
    try {
        Remove-DnsClientDohServerAddress -ServerAddress $toRemove -ErrorAction SilentlyContinue | Out-Null
    }
    catch {
        Write-Warning "Could not remove some DoH entries: $($_.Exception.Message)"
    }

    GetDns
}

### END DNS ###

$NODE_PACKAGE = "OpenJS.NodeJS.LTS"
function AddOrRemoveNodeJS {
    $nodeInstalled = Test-WingetPackageInstalled `
        -Package $NODE_PACKAGE `
        -ErrorAction SilentlyContinue

    if ($nodeInstalled) {
        Write-Host "Node.js is currently installed."

        Write-Host "Node version: $(node -v)"
        Write-Host "npm version:  $(npm -v)"

        $removeNode = Read-Host `
            "Do you want to remove Node.js? (y/N)"

        if ($removeNode -match '^[Yy]$') {
            Remove-WingetApps -Packages $NODE_PACKAGE
        }
    }
    else {
        Write-Host "Node.js is not installed."

        $installNode = Read-Host `
            "Do you want to install Node.js LTS? (y/N)"

        if ($installNode -match '^[Yy]$') {
            Install-WingetApps -Packages $NODE_PACKAGE

            Write-Host ""
            Write-Host "Node.js was installed, but this session may not see it yet." `
                -ForegroundColor Yellow
            Write-Host "Open a new PowerShell window and run 'node -v' or 'npm -v'."
        }
    }
}

function Update-Applications {
    Write-Host ""
    Write-Host $LINE
    Write-Host "Application Update Center" -ForegroundColor Cyan
    Write-Host $LINE

    Log "Starting application update check."

    # Make sure Winget is available
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "$([char]0x274C) Winget is not available." `
            -ForegroundColor Red

        Log "Winget was not found."
        return
    }

    Write-Host ""
    Write-Host "Refreshing Winget package sources..." `
        -ForegroundColor Cyan

    winget source update

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "$([char]0x26A0) Winget source refresh reported an error." `
            -ForegroundColor Yellow

        Log "Winget source update returned exit code $LASTEXITCODE."
    }

    Write-Host ""
    Write-Host "Available application updates:" `
        -ForegroundColor Cyan
    Write-Host ""

    winget upgrade

    Write-Host ""
    $proceed = Read-Host "Install all available application updates? (Y/n)"

    if ($proceed -match '^[Nn]$') {
        Write-Host ""
        Write-Host "Application updates cancelled." `
            -ForegroundColor Yellow

        Log "Application updates cancelled by user."
        return
    }

    Write-Host ""
    Write-Host $LINE
    Write-Host "Installing application updates..." `
        -ForegroundColor Cyan
    Write-Host $LINE
    Write-Host ""

    #--include-unknown

    winget upgrade `
        --all `
        --accept-package-agreements `
        --accept-source-agreements `
        --disable-interactivity

    $upgradeExitCode = $LASTEXITCODE

    Write-Host ""

    if ($upgradeExitCode -eq 0) {
        Write-Host "$([char]0x2705) Application updates completed successfully." `
            -ForegroundColor Green

        Log "Application updates completed successfully."
    }
    else {
        Write-Host "$([char]0x26A0) Winget finished with exit code $upgradeExitCode." `
            -ForegroundColor Yellow

        Write-Host "Some applications may have updated successfully while others were skipped."

        Log "Winget upgrade returned exit code $upgradeExitCode."
    }

    Write-Host ""
    Write-Host "Checking for remaining updates..." `
        -ForegroundColor Cyan
    Write-Host ""

    winget upgrade
    
    Write-Host ""
    Write-Host $LINE
}

function Update-Windows {
    Write-Host ""
    Write-Host "Checking for Windows updates..." `
        -ForegroundColor Cyan

    $session = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()

    $result = $searcher.Search(
        "IsInstalled=0 and Type='Software' and IsHidden=0"
    )

    if ($result.Updates.Count -eq 0) {
        Write-Host "✓ Windows is up to date." `
            -ForegroundColor Green
        return
    }

    Write-Host ""
    Write-Host "Updates found: $($result.Updates.Count)" `
        -ForegroundColor Yellow

    $updates = New-Object -ComObject Microsoft.Update.UpdateColl

    foreach ($update in $result.Updates) {
        Write-Host "  $($update.Title)"

        if (-not $update.EulaAccepted) {
            $update.AcceptEula()
        }

        [void]$updates.Add($update)
    }

    Write-Host ""
    Write-Host "Downloading updates..." `
        -ForegroundColor Cyan

    $downloader = $session.CreateUpdateDownloader()
    $downloader.Updates = $updates
    $downloadResult = $downloader.Download()

    if ($downloadResult.ResultCode -notin 2, 3) {
        Write-Host "✗ Windows Update download failed." `
            -ForegroundColor Red
        return
    }

    Write-Host "Installing updates..." `
        -ForegroundColor Cyan

    $installer = $session.CreateUpdateInstaller()
    $installer.Updates = $updates
    $installResult = $installer.Install()

    Write-Host ""
    Write-Host "Installation result code: $($installResult.ResultCode)"

    if ($installResult.RebootRequired) {
        Write-Host "⚠ Windows requires a reboot." `
            -ForegroundColor Yellow

        $restart = Read-Host "Restart now? (y/N)"

        if ($restart -match '^[Yy]$') {
            Restart-Computer
        }
    }
    else {
        Write-Host "✓ Windows updates completed." `
            -ForegroundColor Green
    }
}

function Install-RepetierServer {
    $program = [PSCustomObject]@{
        Name     = "Repetier Server"
        URL      = "https://download1.repetier.com/files/server/windows/Repetier-Server-1.4.18-win32.exe"
        Switches = "/S"
    }

    ProcessSelectedPrograms @($program) @(1)
}

function menu_browser {

    while ($true) {
        Clear-Host

        Write-Host $LINE
        Write-Host "          Browser Applications Menu" `
            -ForegroundColor Cyan
        Write-Host $LINE

        Write-Host "1) Install Firefox"
        Write-Host "2) Install Brave"
        Write-Host "3) Install Google Chrome"
        Write-Host "4) Install Tor Browser"
        Write-Host "5) Silence Microsoft Edge"
        Write-Host "6) 🔙 Back to Main Menu"
        Write-Host ""

        $choice = Read-Host "Please select an option [1-6]"

        switch ($choice) {
            "1" {
                firefox
            }
            "2" {
                Install-WingetApps -Packages "Brave.Brave"
            }
            "3" {
                Install-WingetApps -Packages "Google.Chrome"
            }
            "4" {
                Install-WingetApps -Packages "TorProject.TorBrowser"
            }
            "5" {
                Disable-EdgeBackground
            }
            "6" {
                menu_main
            }
            default {
                Write-Host "Invalid option. Please try again." `
                    -ForegroundColor Yellow
            }
        }

        if ($choice -ne "6") {
            PressAnyKey
        }
    }
}
function menu_dev {

    while ($true) {
        Clear-Host
        Write-Host $LINE
        Write-Host "   Development Application Menu" `
            -ForegroundColor Cyan
        Write-Host $LINE
        Write-Host "1) Development Utilities (make, etc...)"
        Write-Host "2) Android Studio"
        Write-Host "3) Visual Studio Code"
        Write-Host "4) Visual Studio Code - Extensions"
        Write-Host "5) IntelliJ IDEA"
        Write-Host "6) JetBrains WebStorm"
        Write-Host "7) Arduino"
        Write-Host "8) Glade (GTK+ UI Designer)"
        Write-Host "9) Flutter/Dart"
        Write-Host "10) KICAD"
        Write-Host "11) OpenSSL"
        Write-Host "12) Deploy bash shell tools → ~/.bash_aliases"
        Write-Host "13) Setup GIT ssh signing/authentication keys"
        Write-Host "14) 🔙 Back to Main Menu"
        Write-Host ""
        $choice = Read-Host "Please select an option [1-12]"
        switch ($choice) {
            "1" { AddAllPrograms }
            "2" { Install-WingetApps -Packages "Google.AndroidStudio" }
            "3" { Install-WingetApps -Packages "Microsoft.VisualStudioCode" }
            "4" { Install-VSCodeExtensions }
            "5" { Install-WingetApps -Packages "JetBrains.IntelliJIDEA.Community" }
            "6" { Install-WingetApps -Packages "JetBrains.WebStorm" }
            "7" { Install-WingetApps -Packages "ArduinoSA.IDE.stable" }
            "8" { Install-WingetApps -Packages "gnome.Glade" }
            "9" { Install-WingetApps -Packages "Google.DartSDK" }
            "10" {
                Install-WingetApps -Packages "KiCad.KiCad" # 921MB
            }
            "11" {
                Install-WingetApps -Packages "ShiningLight.OpenSSL.Dev" #
            }
            "14" { menu_main }

            default {
                Write-Host "Invalid option. Please try again."
            }
        }

        PressAnyKey
    }

}

function menu_main {

    while ($true) {
        Clear-Host
        Write-Host $LINE
        Write-Host "           Windows Setup Menu" `
            -ForegroundColor Cyan
        Write-Host $LINE
        Write-Host "Applications" `
            -ForegroundColor DarkYellow
        Write-Host "1) Add Base Programs"
        Write-Host "2) Add Individual Programs"
        Write-Host "3) Install btop"
        Write-Host "4) Install Balena-Etcher"
        Write-Host "5) Install Veracrypt"
        Write-Host "6) Install LibreOffice"
        Write-Host "7) Update Apps"
        Write-Host ""
        Write-Host "Development" `
            -ForegroundColor DarkYellow
        Write-Host "8) Development Applications"
        Write-Host "9) Add/Remove Java"
        Write-Host "10) Add/Remove Node.js®"
        Write-Host ""
        Write-Host "System Configuration" `
            -ForegroundColor DarkYellow
        Write-Host "11) Apply Registry Settings"
        Write-Host "12) Add Windows Features (Telnet Client, XPS)"
        Write-Host "13) Disable OneDrive"
        Write-Host "14) Browser Applications"
        Write-Host "15) Manage SSH Daemon (OpenSSH-Server)"
        Write-Host "16) Manage RDP"
        Write-Host "17) Manage CloudFlare/Quad9 TLS DNS (not working)"
        Write-Host ""
        Write-Host "Graphics & 3d Printing" `
            -ForegroundColor DarkYellow
        Write-Host "18) Install OpenShot"
        Write-Host "19) Install Blender/Gimp/Inkscape"
        Write-Host "20) Install Freecad"
        Write-Host "21) Install OrcaSlicer"
        Write-Host "22) Install Repetier Server"
        Write-Host "23) Install RP-Imager"
        Write-Host ""
        Write-Host "System Information" `
            -ForegroundColor DarkYellow
        Write-Host "24) Get Windows Product Key"
        Write-Host "25) Run Windows Updates"
        Write-Host "26) Add All Programs"
        Write-Host ""
        Write-Host "27) Exit" `
            -ForegroundColor Red
        Write-Host ""
        $choice = Read-Host "Please select an option [1-27]"
        switch ($choice) {
            "1" { AddBasePrograms }
            "2" { AddIndividualPrograms }
            "3" { winget install btop4win }
            "4" {
                #KDE.ISOImageWriter
                Install-WingetApps -Packages "Balena.Etcher" # 190MB
            }
            "5" { Install-WingetApps -Packages "IDRIX.VeraCrypt" }
            "6" { 
                Install-WingetApps -Packages "TheDocumentFoundation.LibreOffice" #
            }
            "7" { Update-Applications }
            "8" { menu_dev }
            "9" { AddOrRemoveJava }
            "10" { AddOrRemoveNodeJS }
            "11" { ApplySettings }
            "12" { WindowsFeatures }
            "13" { DisableOneDrive }
            "14" { menu_browser }
            "15" { ManageSSHD }
            "16" { ManageRDP }
            "17" { ManageDNS }
            "18" { Install-WingetApps -Packages "OpenShot.OpenShot" }
            "19" { 
                Install-WingetApps -Packages "BlenderFoundation.Blender"
                Install-WingetApps -Packages "GIMP.GIMP"
                Install-WingetApps -Packages "Inkscape.Inkscape"
            }
            "20" { Install-WingetApps -Packages "FreeCAD.FreeCAD" }
            "21" { Install-WingetApps -Packages "Flashforge.Orca-Flashforge" }
            "22" { Install-RepetierServer }
            "23" { Install-WingetApps -Packages "RaspberryPiFoundation.RaspberryPiImager" }
            "24" {
                $key = (Get-CimInstance -ClassName SoftwareLicensingService).OA3xOriginalProductKey

                Write-Host ""
                Write-Host "Windows Product Key:" -ForegroundColor Cyan
                Write-Host $key -ForegroundColor Green
                Write-Host ""
            }
            "25" {
                Update-Windows
            }
            "26" { AddAllPrograms }
            "27" {
                Write-Host "Exiting."
                exit 0
            }
            "66" {
                # Run in elevated PowerShell

                # Remove local Group Policy folders (if they exist)
                Remove-Item -Recurse -Force "$env:WinDir\System32\GroupPolicy" -ErrorAction SilentlyContinue
                Remove-Item -Recurse -Force "$env:WinDir\System32\GroupPolicyUsers" -ErrorAction SilentlyContinue

                # Recreate baseline structure (optional but nice)
                New-Item -ItemType Directory "$env:WinDir\System32\GroupPolicy" -ErrorAction SilentlyContinue | Out-Null
                New-Item -ItemType Directory "$env:WinDir\System32\GroupPolicyUsers" -ErrorAction SilentlyContinue | Out-Null

                # Refresh policies
                gpupdate /force

            }
            "pt" {
                Install-WingetApps -Packages "Microsoft.PowerToys"
            }
            "stellarium" {
                Install-WingetApps -Packages "Stellarium.Stellarium" # 455MB
            }
            "ffmpeg" { Install-WingetApps -Packages "Gyan.FFmpeg" }
            "cygwin" { Install-WingetApps -Packages "Cygwin.Cygwin" }
            "ledger" { Install-WingetApps -Packages "LedgerHQ.LedgerLive" }
            default {
                Write-Host "Invalid option. Please try again."
                #Pause
            }
        }

        PressAnyKey

    }
}

menu_main
