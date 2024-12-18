# setup_script.ps1
# Script to set up a Windows environment with various packages.
# Author: threeofthree
# Date: 2024-10-25
# Usage: ./setup_script.ps1
# Note: Must run this script as administrator.
#
# This script is licensed under the MIT License.
# See the LICENSE file in the project root for license information.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Global Variables
$DOWNLOAD_DIR = Join-Path $env:USERPROFILE "Downloads"
$JAVA_DIR = "C:\JAVA"
$LOG_FILE = Join-Path $DOWNLOAD_DIR "setup_script.log"

Function Is-Admin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

If (-not (Is-Admin)) {
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

Function Press-AnyKey {
    Write-Host "Press any key to continue . . ."
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

Function Get-PathFromRegistry {
    Try {
        $pathValue = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment").Path
        return $pathValue
    } Catch {
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
    If ($currentPath -ne $null) {
        $newPath = $currentPath -replace [Regex]::Escape("$JAVA_DIR\jdk-23.0.1\bin;"), ""
        Set-PathInRegistry $newPath
    }

    # Remove Java directory
    If (Test-Path $JAVA_DIR) {
        Remove-Item -Path $JAVA_DIR -Recurse -Force
    } Else {
        Write-Host "Java directory '$JAVA_DIR' does not exist."
        Log "Java directory '$JAVA_DIR' does not exist."
    }

    Write-Host "Java has been removed."
    Log "Java has been removed."
    Write-Host "Please restart your computer or log off and log back in for changes to take effect."
    Log "Please restart your computer or log off and log back in for changes to take effect."
    Press-AnyKey
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
        wget $DOWNLOAD_URL -OutFile $javaZip
    } Catch {
        Write-Host "Failed to download Java."
        Log "Failed to download Java."
        Press-AnyKey
        return
    }

    If (-not (Test-Path $JAVA_DIR)) {
        New-Item -ItemType Directory -Path $JAVA_DIR | Out-Null
    }

    Write-Host "Extracting Java..."
    Log "Extracting Java..."

    Try {
        Expand-Archive -Path $javaZip -DestinationPath $JAVA_DIR -Force
    } Catch {
        Write-Host "Failed to extract Java."
        Log "Failed to extract Java."
        Press-AnyKey
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
    Press-AnyKey
}

Function AddOrRemoveJava {
    # Check if Java is installed
    $javaInstalled = $false
    Try {
        java -version > $null 2>&1
        If ($LASTEXITCODE -eq 0) {
            $javaInstalled = $true
        }
    } Catch {
        $javaInstalled = $false
    }

    If ($javaInstalled) {
        Write-Host "Java is currently installed."
        $removeJava = Read-Host "Do you want to remove Java? (y/N)"
        If ($removeJava -match '^[Yy]$') {
            Remove-Java
        }
    } Else {
        Write-Host "Java is not installed."
        $installJava = Read-Host "Do you want to install Java? (y/N)"
        If ($installJava -match '^[Yy]$') {
            Install-Java
        }
    }
}

Function Load-Programs {
    If (-not (Test-Path "app_list.txt")) {
        Write-Host "Error: app_list.txt not found."
        Log "Error: app_list.txt not found."
        Press-AnyKey
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
                Name = $progName
                URL = $progURL
                Switches = $installSwitches
            })
        }
    }

    If ($programs.Count -eq 0) {
        Write-Host "No programs found in app_list.txt."
        Log "No programs found in app_list.txt."
        Press-AnyKey
        return $null
    }

    return $programs
}

Function AddAllPrograms {
    $programs = Load-Programs
    If ($programs -eq $null) { return }

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

    Process-SelectedPrograms $programs $selectedIndices
}

Function AddIndividualPrograms {
    $programs = Load-Programs
    If ($programs -eq $null) { return }

    Write-Host "Available Programs:"
    Log "Available Programs:"
    for ($i=0; $i -lt $programs.Count; $i++) {
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

    Process-SelectedPrograms $programs $selectedIndices
}

Function Process-SelectedPrograms($programs, $selectedIndices) {
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

        $prog = $programs[$intIdx-1]
        Write-Host "Processing $($prog.Name)..."
        Log "Processing $($prog.Name)..."

        Write-Host "Downloading $($prog.Name)..."
        Log "Downloading $($prog.Name)..."
        $fileName = [System.IO.Path]::GetFileName($prog.URL)
        $installerPath = Join-Path $DOWNLOAD_DIR $fileName

        If (Test-Path $installerPath) {
            Write-Host "$fileName already exists. Skipping download."
            Log "$fileName already exists. Skipping download."
        } Else {
            Try {
                wget $prog.URL -OutFile $installerPath
                Write-Host "$($prog.Name) downloaded successfully."
                Log "$($prog.Name) downloaded successfully."
            } Catch {
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
                    $process = Start-Process $installerPath -ArgumentList $prog.Switches,"/norestart","/quiet" -Wait -PassThru
                    $processExitCode = $process.ExitCode
                } ElseIf ($ext -eq ".msi") {
                    $process = Start-Process "msiexec" -ArgumentList "/i",$installerPath,$prog.Switches,"/norestart","/quiet" -Wait -PassThru
                    $processExitCode = $process.ExitCode
                } Else {
                    Write-Host "Unknown installer type for $($prog.Name). Cannot install."
                    Log "Unknown installer type for $($prog.Name). Cannot install."
                    continue
                }

                If ($processExitCode -eq 0) {
                    $installSuccess = $true
                } Else {
                    Write-Host "Installer returned error code $processExitCode"
                    Log "Installer returned error code $processExitCode"
                }
            } Catch {
                Write-Host "Error running installer for $($prog.Name): $($_.Exception.Message)"
                Log "Error running installer for $($prog.Name): $($_.Exception.Message)"
            }

            If ($installSuccess) {
                Write-Host "$($prog.Name) installed successfully."
                Log "$($prog.Name) installed successfully."
            } Else {
                Write-Host "Failed to install $($prog.Name)."
                Log "Failed to install $($prog.Name)."
            }
        } Else {
            Write-Host "Installer for $($prog.Name) not found."
            Log "Installer for $($prog.Name) not found."
        }
    }

    Write-Host "All selected programs have been processed."
    Log "All selected programs have been processed."
    Pause
}

Function MainMenu {
    while ($true) {
        cls
        Write-Host "--------------------------------------------"
        Write-Host "Setup Script Menu"
        Write-Host "--------------------------------------------"
        Write-Host "1) Add/Remove Java"
        Write-Host "2) Add All Programs"
        Write-Host "3) Add Individual Programs"
        Write-Host "4) Exit"
        Write-Host "--------------------------------------------"
        $choice = Read-Host "Please select an option [1-4]"
        switch ($choice) {
            "1" { AddOrRemoveJava }
            "2" { AddAllPrograms }
            "3" { AddIndividualPrograms }
            "4" {
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
