# WindowsSetup

# Windows Setup Scripts

## Overview

The `setup_script.ps1` is a PowerShell script designed to automate the installation and removal of Java, as well as download and install a list of predefined programs on a Windows system. The script provides a menu-driven interface that allows users to:

- Add or remove Java.
- Download and install all programs from a configured list.
- Select and install individual programs from that list.
- Exit the script.

By automating these tasks, the script streamlines the setup process on a new or existing Windows machine, saving time and reducing manual effort.

---

## Table of Contents

1. [Prerequisites](#prerequisites)  
2. [Setup Instructions](#setup-instructions)  
3. [Running PowerShell Scripts](#running-powershell-scripts)  
   - [Creating the Script File](#creating-the-script-file)  
   - [Setting the Execution Policy](#setting-the-execution-policy)  
4. [Usage Instructions](#usage-instructions)  
   - [Main Menu Options](#main-menu-options)  
   - [Adding or Removing Java](#adding-or-removing-java)  
   - [Adding Programs](#adding-programs)  
5. [Configuration Files](#configuration-files)  
   - [`app_list.txt` Format](#app_listtxt-format)  
6. [Logging](#logging)  
7. [Troubleshooting](#troubleshooting)  
8. [Important Notes](#important-notes)  
9. [Author and License](#author-and-license)

---

## Prerequisites

Before running the `setup_script.ps1`, ensure that the following prerequisites are met:

1. **Windows Operating System**:  
   The script is designed for Windows environments.

2. **Administrative Privileges**:  
   The script must be run with administrative rights to install software and modify system environment variables.

3. **Internet Connection**:  
   Required to download Java and the listed programs.

---

## Setup Instructions

1. **Download the Script and Configuration File**:  
   - Place `setup_script.ps1` in a directory of your choice.
   - Ensure that `app_list.txt` is in the **same directory** as `setup_script.ps1`.

2. **Run PowerShell as Administrator**:  
   - Right-click on PowerShell and select **"Run as administrator"**.

---

## Running PowerShell Scripts

### Creating the Script File

If you haven't already:

- Open a text editor (e.g., Notepad) or an IDE (e.g., Visual Studio Code).
- Write or copy the `setup_script.ps1` content into the editor.
- Save the file with a `.ps1` extension (e.g., `setup_script.ps1`).

### Setting the Execution Policy

By default, PowerShell may restrict running scripts. Adjust the execution policy as needed:

- **Check the current policy**:

  ```powershell
  Get-ExecutionPolicy
  ```

- **Temporarily change the execution policy for the current session**:

  ```powershell
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  ```

- **Permanently allow scripts to run for the current user**:

  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

**Note**:  
Use `RemoteSigned` or `AllSigned` for safety. Avoid `Unrestricted` unless you understand the risks.

---

## Usage Instructions

Once you've set the execution policy and opened an elevated PowerShell session:

1. **Navigate to the Script Directory**:  
   ```powershell
   cd path\to\your\script
   ```

2. **Run the Script**:  
   ```powershell
   ./setup_script.ps1
   ```

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

- If Java is not installed, the script will prompt to install it.
- If Java is installed, the script will prompt to remove it.
- After adding or removing Java, a system restart or logging off and back on is recommended to apply the changes.

### Adding Programs

**Option 2: Add All Programs**  
- Downloads and installs all programs listed in `app_list.txt` after confirming that you wish to proceed.

**Option 3: Add Individual Programs**  
- Displays a numbered list of available programs.
- Allows you to select specific programs by entering their numbers separated by commas.
- Enter `0` at the individual program menu to exit back to the main menu.

The script will download and install the chosen programs silently if possible, logging successes and failures.

### Exiting the Script

**Option 4: Exit**  
- Ends the script execution.

---

## Configuration Files

### `app_list.txt` Format

`app_list.txt` defines the programs to be downloaded and installed. Each line follows the format:

```
ProgramName|DownloadURL|InstallSwitches
```

- **`ProgramName`**: The display name of the program.
- **`DownloadURL`**: Direct URL to the program's installer.
- **`InstallSwitches`**: Command-line switches for silent or unattended installation.

**Notes**:

- Lines starting with `#` are treated as comments and are ignored.
- Ensure no extra spaces around the `|` delimiter.
- Update the install switches as needed for silent installations.

---

## Logging

- The script creates a `setup_script.log` file in your Downloads directory (`%USERPROFILE%\Downloads`).
- This log file records actions, successes, and failures.
- Review this log if you encounter issues or need to troubleshoot.

---

## Troubleshooting

1. **Script Does Not Run as Administrator**:
   - Ensure you've right-clicked on PowerShell and selected **"Run as administrator"**.
   - Confirm that your account has administrative privileges.

2. **Execution Policy Issues**:
   - If the script won't run, adjust the execution policy as described in [Running PowerShell Scripts](#running-powershell-scripts).

3. **Program Fails to Download or Install**:
   - Check the URLs in `app_list.txt`.
   - Ensure you have a stable internet connection.
   - Review `setup_script.log` for error messages.
   - Verify silent install switches for each program.

4. **Unknown Installer Types**:
   - The script attempts to handle `.exe` and `.msi` files.
   - If an installer uses a different extension or special parameters, update the script or switches accordingly.

5. **Java Installation Issues**:
   - Check if the download URL for Java is correct and accessible.
   - Ensure sufficient disk space on `C:\`.

6. **Environment Variables Not Updated**:
   - After adding or removing Java, restart or log off/log on to apply changes.

---

## Important Notes

- **Modify `app_list.txt` with Caution**:
  - Backup the original file before making changes.
  - Ensure correct formatting and URLs.

- **Use Safe Execution Policies**:
  - Consider `RemoteSigned` or `AllSigned` for safer script execution.
  - Avoid `Unrestricted` unless you understand the risks.

- **License Agreements**:
  - By installing software using this script, you agree to the license terms of each program.
  - Review each application's license if necessary.

---

## Author and License

**Author**: threeofthree  
**Date**: 2024-10-25

This script is licensed under the [MIT License](https://opensource.org/licenses/MIT).  
See the `LICENSE` file in the project root for license information.

**Disclaimer**: This script is intended for educational and automation purposes.  
Always review the script and `app_list.txt` before execution. Use at your own risk.

---

**Contact Information**:  
For questions, suggestions, or assistance, please contact the script maintainer or consult the documentation for the programs involved.