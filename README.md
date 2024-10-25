# WindowsSetup
# Setup Script README

## Overview

The `setup_script.bat` is a Windows batch script designed to automate the installation and removal of Java, as well as download and install a list of predefined programs on a Windows system. The script provides a menu-driven interface that allows users to:

- Add or remove Java.
- Download and install all programs from a list.
- Select and install individual programs from the list.
- Exit the script.

This script is intended to streamline the setup process on a new or existing Windows machine by automating repetitive tasks.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Setup Instructions](#setup-instructions)
3. [Usage Instructions](#usage-instructions)
   - [Main Menu Options](#main-menu-options)
   - [Adding or Removing Java](#adding-or-removing-java)
   - [Adding Programs](#adding-programs)
4. [Configuration Files](#configuration-files)
   - [`app_list.txt` Format](#app_listtxt-format)
5. [Logging](#logging)
6. [Troubleshooting](#troubleshooting)
7. [Important Notes](#important-notes)
8. [License](#license)

---

## Prerequisites

Before running the `setup_script.bat`, ensure that the following prerequisites are met:

1. **Windows Operating System**: The script is designed for Windows environments.

2. **Administrative Privileges**: The script must be run with administrative rights to install software and modify system environment variables.

3. **`s_wget.exe` Utility**:

   - The script relies on `s_wget.exe` to download files.
   - **Download `s_wget.exe`**:

     - You can download `s_wget.exe` from [Eternal Download Link](https://eternallybored.org/misc/wget/) or [GNU Wget for Windows](https://gnuwin32.sourceforge.net/packages/wget.htm).
     - Ensure that the downloaded `s_wget.exe` is placed either in the same directory as `setup_script.bat` or added to your system `PATH`.

4. **Internet Connection**: Required to download Java and the listed programs.

---

## Setup Instructions

1. **Download the Script and Configuration File**:

   - Place `setup_script.bat` in a directory of your choice.
   - Ensure that `app_list.txt` is in the **same directory** as `setup_script.bat`.

2. **Prepare `s_wget.exe`**:

   - Download `s_wget.exe` as per the instructions in the [Prerequisites](#prerequisites) section.
   - Place `s_wget.exe` in the same directory as the script or ensure it's accessible via the system `PATH`.

3. **Verify Administrative Access**:

   - Ensure you have administrative privileges on the system.
   - Right-click `setup_script.bat` and select **"Run as administrator"**.

---

## Usage Instructions

### Main Menu Options

Upon running the script, you will see the following menu:

```
--------------------------------------------
Setup Script Menu
--------------------------------------------
1) Add/Remove Java
2) Add All Programs
3) Add Individual Programs
4) Exit
--------------------------------------------
Please select an option [1-4]:
```

Enter the number corresponding to the action you wish to perform.

### Adding or Removing Java

#### Option 1: Add/Remove Java

- **Adding Java**:

  - If Java is not detected on your system, the script will prompt:

    ```
    Java is not installed.
    Do you want to install Java? (y/N):
    ```

  - Enter `Y` to proceed with the installation.
  - The script will download the OpenJDK ZIP file, extract it to `C:\JAVA`, and update the `JAVA_HOME` environment variable and system `PATH`.

- **Removing Java**:

  - If Java is detected, the script will prompt:

    ```
    Java is currently installed.
    Do you want to remove Java? (y/N):
    ```

  - Enter `Y` to proceed with the removal.
  - The script will delete the `C:\JAVA` directory and remove Java entries from the `JAVA_HOME` variable and system `PATH`.

- **Restart Required**:

  - After adding or removing Java, a system restart or logging off and back on is recommended to apply the changes.

### Adding Programs

#### Option 2: Add All Programs

- The script will display a warning:

  ```
  This process will download and install all X programs.
  This may take a significant amount of time.
  Do you wish to continue? (Y/N):
  ```

- Enter `Y` to proceed.
- The script will download and install all programs listed in `app_list.txt`.

#### Option 3: Add Individual Programs

- The script will display a numbered list of available programs, followed by:

  ```
  0) Exit

  Enter the numbers of the programs to download and install, separated by commas (e.g., 1,3,5):
  ```

- Enter the numbers corresponding to the programs you wish to install, separated by commas.
- Enter `0` to return to the main menu.
- The script will process your selection, downloading and installing the chosen programs.

---

## Configuration Files

### `app_list.txt` Format

The `app_list.txt` file contains the list of programs to be downloaded and installed. Each line in the file represents a program and follows the format:

```
ProgramName|DownloadURL|InstallSwitches
```

- **`ProgramName`**: The name of the program (used for display purposes).
- **`DownloadURL`**: Direct URL to the program's installer.
- **`InstallSwitches`**: Command-line switches for silent or unattended installation.

#### Example `app_list.txt`

```plaintext
# ProgramName|DownloadURL|InstallSwitches
Audacity|https://github.com/audacity/audacity/releases/download/Audacity-3.6.4/audacity-win-3.6.4-64bit.exe|/S
Shotcut|https://sourceforge.net/projects/shotcut/files/v24.09.13/shotcut-win64-240913.exe/download|/S
OpenShot|https://github.com/OpenShot/openshot-qt/releases/download/v3.1.1/OpenShot-v3.1.1-x86_64.exe|/silent
VLC|https://get.videolan.org/vlc/3.0.18/win64/vlc-3.0.18-win64.exe|/S
Blender|https://download.blender.org/release/Blender3.6/blender-3.6.2-windows-x64.msi|/quiet
GIMP|https://download.gimp.org/pub/gimp/v2.10/windows/gimp-2.10.34-setup.exe|/VERYSILENT
Inkscape|https://inkscape.org/gallery/item/53697/inkscape-1.4_2024-10-11_86a8ad7-x64.msi|/quiet
Upscayl|https://github.com/upscayl/upscayl/releases/download/v2.11.5/upscayl-2.11.5-win.exe|/S
FreeCAD|https://github.com/FreeCAD/FreeCAD/releases/download/0.21.2/FreeCAD-0.21.2-WIN-x64-installer-1.exe|/S
OrcaSlicer|https://github.com/SoftFever/OrcaSlicer/releases/download/v2.1.0/OrcaSlicer_Windows_Installer_V2.1.0.exe|/S
Repetier-Server|https://download3.repetier.com/files/monitor/win/Repetier-Server Monitor Setup 1.4.7.exe|/S
Arduino IDE|https://downloads.arduino.cc/arduino-ide/arduino-ide_2.2.1_Windows_64bit.exe|/S
Android Studio|https://redirector.gvt1.com/edgedl/android/studio/install/2022.3.1.20/android-studio-2022.3.1.20-windows.exe|/S
VSCode|https://update.code.visualstudio.com/latest/win32-x64-user/stable|/verysilent
VSCodium|https://github.com/VSCodium/vscodium/releases/download/1.82.2.23225/VSCodiumSetup-x64-1.82.2.23225.exe|/verysilent
Geany|https://download.geany.org/geany-1.38_setup.exe|/S
LibreOffice|https://ftp.osuosl.org/pub/tdf/libreoffice/stable/24.8.2/win/x86_64/LibreOffice_24.8.2_Win_x86-64.msi|/quiet
Transmission|https://github.com/transmission/transmission/releases/download/4.0.6/transmission-4.0.6-x64.msi|/quiet
Stellarium|https://github.com/Stellarium/stellarium/releases/download/v24.3/stellarium-24.3-qt6-win64.exe|/S
```

**Notes**:

- Lines starting with `#` are treated as comments and ignored.
- Ensure that there are no extra spaces around the `|` delimiter.
- Verify that the download URLs are correct and accessible.
- Update the install switches as needed for silent installations.

---

## Logging

- The script creates a log file named `setup_script.log` in your Downloads directory (`%USERPROFILE%\Downloads`).
- The log file records actions taken by the script, including successes and failures.
- Use the log file to troubleshoot issues or review the installation process.

---

## Troubleshooting

1. **Script Does Not Run as Administrator**:

   - Ensure you right-click `setup_script.bat` and select **"Run as administrator"**.
   - Verify that your user account has administrative privileges.

2. **`s_wget.exe` Not Found**:

   - Confirm that `s_wget.exe` is in the same directory as the script or accessible via the system `PATH`.
   - Check for typos in the filename (`s_wget.exe`).

3. **Program Fails to Download**:

   - Verify the download URL in `app_list.txt` by accessing it through a web browser.
   - Ensure you have an active internet connection.

4. **Silent Installation Fails**:

   - Check the install switches for the program in `app_list.txt`.
   - Consult the program's documentation for correct silent installation parameters.
   - Some installers may not support silent installation or may require different switches.

5. **Installer Type Not Recognized**:

   - The script recognizes `.exe` and `.msi` installer files.
   - If an installer has a different extension, the script may not be able to process it.
   - Update the script to handle additional installer types if necessary.

6. **Java Installation Issues**:

   - Ensure that the download URL for Java is correct and accessible.
   - Check for sufficient disk space on the `C:\` drive.

7. **Environment Variables Not Updated**:

   - After installing or removing Java, restart your computer or log off and back on to apply changes to environment variables.

8. **Review the Log File**:

   - Open `setup_script.log` in your Downloads directory to view detailed logs.
   - Look for error messages or codes that can provide insights into issues.

---

## Important Notes

- **Modify `app_list.txt` with Caution**:

  - Ensure that the file format is maintained when adding or removing programs.
  - Backup the original `app_list.txt` before making changes.

- **Internet Security Settings**:

  - Some security software may block script execution or downloads.
  - Temporarily adjust your security settings or whitelist the script if necessary.

- **System Requirements for Programs**:

  - Verify that your system meets the requirements for each program you intend to install.
  - Some programs may require additional dependencies or specific hardware.

- **License Agreements**:

  - By installing software using this script, you agree to the license terms of each individual program.
  - Review the license agreements as necessary.

---

## License

This script is provided "as is" without warranty of any kind. Use it at your own risk. Ensure compliance with all software licenses and terms of use for the programs being installed.

---

**Disclaimer**: This script is intended for educational and automation purposes. Always exercise caution when running scripts that modify system settings or install software. Review the script's content and understand its functionality before execution.

---

**Contact Information**:

For questions, suggestions, or assistance, please reach out to the script maintainer or consult the documentation for the specific programs involved.
