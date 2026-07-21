# WindowsSetup

# Windows Setup Scripts

## Overview

`setup_script.ps1` is a menu-driven PowerShell setup and maintenance utility for Windows 11. It is designed to reduce the repetitive work involved in preparing a new installation or bringing an existing machine into a preferred configuration.

The script can:

- Install a curated base set of applications through WinGet.
- Install selected applications individually or install the complete application set.
- Manage development tools, Java, Node.js, browsers, and VS Code extensions.
- Apply Windows and registry preferences.
- Configure optional Windows features.
- Manage OneDrive, OpenSSH Server, Remote Desktop, and encrypted DNS settings.
- Run application updates and Windows Update.
- Install graphics, media, development, and 3D-printing software.
- Display useful system information such as the embedded Windows product key.

Some options make system-wide changes and therefore require an elevated PowerShell session. Review the script before running it and use only the sections appropriate for the machine being configured.

### Optional: create a local account during Windows setup

During the Windows 11 out-of-box setup, Microsoft may require an internet connection and Microsoft account sign-in. To create a local account instead, press **Shift+F10** to open Command Prompt, then run:

```cmd
start ms-cxh:localonly
```

This opens the local-account setup flow. Availability may depend on the Windows 11 build being installed.

[Microsoft Windows 11 Download Page](https://www.microsoft.com/en-us/software-download/windows11)

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Download, Setup, and Running](#download-setup-and-running)
3. [Execution Policy](#execution-policy)
4. [Usage Instructions](#usage-instructions)
   - [Main Menu Options](#main-menu-options)
5. [Logging](#logging)
6. [Troubleshooting](#troubleshooting)
7. [Author and License](#author-and-license)

---

## Prerequisites

Before running `setup_script.ps1`, make sure the following are available:

- **Windows 11**
- **An administrator account**
- **An active internet connection**
- **WinGet**, which is included with current Windows 11 installations through App Installer

The script performs software installation, registry changes, Windows feature management, service configuration, and other system-wide tasks, so it must be run from an elevated PowerShell window.

---

## Download, Setup, and Running

The easiest way to get the complete project is to download the repository as a ZIP file from GitHub.

1. Open the repository page.
2. Select **Code**.
3. Choose **Download ZIP**.
4. Extract the ZIP file to a convenient location.
5. Open the extracted folder.
6. Open PowerShell with **Run as administrator**.
7. Navigate to the extracted project folder:

   ```powershell
   cd path\to\WindowsSetup
   ```

8. Run the script:

   ```powershell
   .\setup_script.ps1
   ```

Keep the files from the ZIP together in the same folder so supporting files, such as the VS Code extension list, remain available to the script.

---

## Execution Policy

PowerShell may block script execution depending on the current system policy.

Check the current policy:

```powershell
Get-ExecutionPolicy
```

Temporarily allow the script for the current PowerShell session:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Or allow locally created scripts for the current user:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

`RemoteSigned` is generally preferable to `Unrestricted`. Review scripts before running them, especially when they make administrative changes.

---

## Usage Instructions

After launching the script, enter the number for the task you want to run. Some menu items open additional submenus for development tools and browsers.

The script is designed so individual options can be run separately. You do not need to run every item, and many options are safe to run again when maintaining an existing Windows installation.

### Main Menu Options

Upon running the script, you will see the following menu:

```
────────────────────────────────────────────
           Windows Setup Menu
────────────────────────────────────────────
Applications
1) Add Base Programs
2) Add Individual Programs
3) Install btop
4) Install Balena-Etcher
5) Install Veracrypt
6) Install LibreOffice
7) Update Apps

Development
8) Development Applications
9) Add/Remove Java
10) Add/Remove Node.js®

System Configuration
11) Apply Registry Settings
12) Add Windows Features (Telnet Client, XPS)
13) Disable OneDrive
14) Browser Applications
15) Manage SSH Daemon (OpenSSH-Server)
16) Manage RDP
17) Manage CloudFlare/Quad9 TLS DNS (testing)

Graphics & 3d Printing
18) Install OpenShot
19) Install Blender/Gimp/Inkscape
20) Install Freecad
21) Install OrcaSlicer
22) Install Repetier Server
23) Install RP-Imager

System Information
24) Get Windows Product Key
25) Run Windows Updates
26) Add All Programs

27) Exit

Please select an option [1-27]:
```

Enter the number corresponding to the action you wish to perform.

---

---

## Logging

The script writes activity to:

```text
%USERPROFILE%\Downloads\setup_script.log
```

The log can help identify which action was attempted and where an installation or configuration step stopped. Some external tools, including WinGet and Windows system utilities, may also display additional details directly in the PowerShell window.

---

## Troubleshooting

### The script says it must be run as administrator

Close the current PowerShell window, open PowerShell with **Run as administrator**, return to the project folder, and run the script again.

### PowerShell blocks the script

Use the temporary execution-policy command shown in the [Execution Policy](#execution-policy) section, then rerun the script from the same PowerShell session.

### WinGet is missing or unavailable

Install or update **App Installer** from Microsoft Store, then open a new PowerShell window and verify:

```powershell
winget --version
```

### An application does not install or update

Some applications use publisher-managed installers or internal update systems and may not support every WinGet operation. Review the console output and the setup log, then use the application's own updater when required.

### A setting does not appear immediately

Some registry, service, environment-variable, and Windows feature changes require Explorer to restart, a new PowerShell session, signing out, or rebooting Windows.

### Windows Update or feature installation fails

Confirm the machine is online, restart Windows if an update is pending, and run the relevant menu option again.

---

## Author and License

**Author:** threeofthree  
**Original date:** 2024-10-25

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT). See the `LICENSE` file in the repository for the complete license text.

**Disclaimer:** This project is provided for educational and automation purposes. Review the script before running it. The script can install software, change registry values, configure services, modify networking settings, and enable or disable Windows features. Use it at your own risk.
