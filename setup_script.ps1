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

$LINE = "--------------------------------------------"

Function IsAdmin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

If (-not (IsAdmin)) {
    Write-Host "You must run this script as administrator!"
    Pause
    Exit 1
}

If (-not (Test-Path $LOG_FILE)) {
    New-Item -ItemType File -Path $LOG_FILE | Out-Null
}

Function Log($message) {
    $message | Out-File -Append -FilePath $LOG_FILE
}

Function PressAnyKey {
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
    Write-Host "`nPress any key to continue..." -NoNewline
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Function Get-PathFromRegistry {
    Try {
        $pathValue = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment").Path
        return $pathValue
    }
    Catch {
        return $null
    }
}

Function Set-PathInRegistry($newPath) {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -Name "Path" -Type ExpandString -Value $newPath
}

Function Remove-Java {
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

Function Install-Java {
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

Function AddOrRemoveJava {
    # Check if Java is installed
    $javaInstalled = $false
    Try {
        java -version > $null 2>&1
        If ($LASTEXITCODE -eq 0) {
            $javaInstalled = $true
        }
    }
    Catch {
        $javaInstalled = $false
    }

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

Function LoadPrograms {
    If (-not (Test-Path "app_list.txt")) {
        Write-Host "Error: app_list.txt not found."
        Log "Error: app_list.txt not found."
        PressAnyKey
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
        PressAnyKey
        return $null
    }

    return $programs
}

Function AddAllPrograms {
    $programs = LoadPrograms
    If ($null -eq $programs) { return }

    $count = $programs.Count
    Write-Host "This process will download and install all $count programs."
    Write-Host "This may take a significant amount of time."
    $proceed = Read-Host "Do you wish to continue? (Y/N)"
    If ($proceed -notmatch '^[Yy]$') {
        Write-Host "Operation cancelled."
        return
    }

    # Build a list of all program indices
    $selectedIndices = 1..$count

    ProcessSelectedPrograms $programs $selectedIndices
}

Function AddIndividualPrograms {
    $programs = LoadPrograms
    If ($null -eq $programs) { return }

    Write-Host "Available Programs:"
    Log "Available Programs:"
    for ($i = 0; $i -lt $programs.Count; $i++) {
        $idx = $i + 1
        Write-Host "$idx) $($programs[$i].Name)"
        Log "$idx) $($programs[$i].Name)"
    }

    Write-Host "0) Exit"
    Log "0) Exit"
    Write-Host
    $selected = Read-Host "Enter the numbers of the programs to download and install, separated by commas (e.g., 1,3,5):"

    $selectedIndices = ($selected -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }

    If ($selectedIndices -contains '0') {
        return
    }

    ProcessSelectedPrograms $programs $selectedIndices
}

Function ProcessSelectedPrograms($programs, $selectedIndices) {
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

Function ApplySettings {

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
    #reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_DWORD /d 1 /f

    # Show file extensions
    Write-Host "Setting file extensions to be visible..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -Force

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

    Write-Host "Registry changes applied successfully."


    # Restart Explorer to apply changes
    Write-Host "Restarting Explorer to apply changes..."
    Stop-Process -Name explorer -Force
    Start-Process explorer


    Show-Message "Registry settings applied."

}

Function WindowsFeatures {

    $features = @("Printing-XPSServices-Features", "TelnetClient", "ssh-agent")

    Write-Host ""

    foreach ($feature in $features) {
        Write-Host "Installing $feature..."
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
    }


    Show-Message("All selected features have been installed.")

}

Function DisableOneDrive {

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


Function ManageSSHD {

    # Prompt the user for action
    $choice = (Read-Host "Do you want to (I)nstall or (U)ninstall OpenSSH-Server? [I/U]").Trim()

    if ($choice -ieq "I") {
        Write-Host "Installing and configuring OpenSSH-Server..." -ForegroundColor Cyan

        #Add-WindowsFeature -Name "OpenSSH-Server"
        #Enable-WindowsOptionalFeature -Online -FeatureName "OpenSSH-Server" -All -NoRestart
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

        #Set-Service -Name ssh-agent -StartupType Automatic
        Set-Service -Name sshd -StartupType Automatic
        

        Start-Service sshd
        New-NetFirewallRule -DisplayName "OpenSSH-Server" -LocalPort 22 -Action Allow -Protocol TCP
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
        Remove-NetFirewallRule -DisplayName "OpenSSH-Server" -ErrorAction SilentlyContinue

        Get-WindowsCapability -Online | Where-Object Name -like "OpenSSH.Server*"
        Write-Host "$([char]0x274C) You must reboot to complete removal!" -ForegroundColor Red
        Write-Host "$([char]0x274C) OpenSSH-Server has been stopped and disabled." -ForegroundColor Red
        Write-Host "$([char]0x274C) Firewall rule (OpenSSH-Server) has been removed." -ForegroundColor Red
        Write-Host "$([char]0x2139)  If you need OpenSSH-Server again, rerun this script and choose Install." -ForegroundColor Yellow
        Write-Host ""
    }
    else {
        Write-Host "Invalid choice. Please run the script again and select (I)nstall or (U)ninstall." -ForegroundColor Yellow
    }



    PressAnyKey

}

Function MainMenu {

    while ($true) {
        Clear-Host
        Write-Host $LINE
        Write-Host "Setup Script Menu"
        Write-Host $LINE
        Write-Host "1) Add/Remove Java"
        Write-Host "2) Add All Programs"
        Write-Host "3) Add Individual Programs"
        Write-Host "4) Apply Registry Settings"
        Write-Host "5) Add Windows Features (Telnet Client, XPS)"
        Write-Host "6) Disable OneDrive"
        Write-Host "7) Manage SSH Daemon (OpenSSH-Server)"
        Write-Host "8) Exit"
        Write-Host $LINE
        $choice = Read-Host "Please select an option [1-8]"
        switch ($choice) {
            "1" { AddOrRemoveJava }
            "2" { AddAllPrograms }
            "3" { AddIndividualPrograms }
            "4" { ApplySettings }
            "5" { WindowsFeatures }
            "6" { DisableOneDrive }
            "7" { ManageSSHD }
            "8" {
                Write-Host "Exiting."
                exit 0
            }
            default {
                Write-Host "Invalid option. Please try again."
                Pause
            }
        }
    }
}

MainMenu
