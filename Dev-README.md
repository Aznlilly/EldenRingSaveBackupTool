# Elden Ring Save File Backup Tool

A PowerShell GUI application that automatically backs up your Elden Ring save file when changes are detected or on a timer interval. Features intelligent debouncing, zip compression, and support for mod launchers.

## Features

- **File Change Detection**: Automatically backs up when the save file is modified with intelligent 10-second debouncing
- **Timer-based Backup**: Regular backups at configurable intervals (30 seconds to 1 hour)
- **Zip Compression**: Automatic compression reduces backup size by ~90% (30MB → 3MB)
- **Mod Launcher Support**: Launch Elden Ring with custom executables and arguments (e.g., ModEngine2)
- **Responsive UI**: Modern, DPI-aware interface that scales perfectly on all screen sizes (1080p, 1440p, 4K)
- **Multi-language Support**: Interface available in 6 languages (English, Spanish, French, Japanese, Chinese, Korean)
- **Smart Backup Retention**: Default 50 backups with automatic cleanup
- **System Tray Integration**: Run in background with system tray icon
- **Configuration Persistence**: Settings are saved and restored between sessions
- **Smart Backup Naming**: Timestamps and file type prefixes with original filename preserved for easy restoration
- **Multi-format Support**: Works with both Elden Ring (.sl2) and Seamless Coop (.co2) save files
- **Real-time Logging**: Live activity log with scrollable history
- **Single Instance Protection**: Prevents multiple instances from running simultaneously

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- .NET Framework (for Windows Forms)
- Elden Ring save file (typically located in `%USERPROFILE%\AppData\Roaming\EldenRing\`)

## Usage

### Quick Start Options

#### **Silent Mode (Recommended)**
- **Windows**: Double-click `StartEldenRingBackup.bat`
- **No console window** - Runs completely in background
- **Perfect for daily use** - Clean, no clutter
- **Custom icon** - Application window and system tray show the Elden Ring icon

#### **Console Mode (Debug)**
- **Windows**: Double-click `StartEldenRingBackup-Console.bat`
- **Shows console window** - See all monitoring activity and logs
- **Great for troubleshooting** - Watch what's happening

#### **Direct PowerShell**
- **PowerShell**: Run `.\EldenRingSaveBackup.ps1`
- **Always shows console** - For developers and advanced users

The application starts in system tray mode by default - you'll see a tray icon in your system tray area.

## Configuration

The application features a modern, responsive interface with organized sections:

1. **Language Selection**: Choose your preferred interface language (6 languages supported)
2. **Game Settings**: 
   - Select your Elden Ring executable path (supports mod launchers like ModEngine2)
   - Configure launch arguments (e.g., `-t er -c .\config_eldenring.toml`)
   - Choose your save file location (usually `ER0000.sl2` or `ER0000.co2`)
3. **Save File Settings**:
   - Browse for your Elden Ring save file
   - Set backup folder location
4. **Backup Settings**:
   - Configure maximum number of backups to keep (default: 50, range: 1-100)
   - Choose backup method (File Change Detection or Timer Interval)
   - Set timer interval (30 seconds to 1 hour)
   - Automatic zip compression (90% space savings)
5. **Control Panel**:
   - Start/Stop monitoring
   - Manual backup now
   - Launch Elden Ring (with custom arguments)
   - Minimize to system tray
6. **Status & Logging**: Real-time status updates and activity log with compression statistics

## Default Save File Locations

Elden Ring save files are typically located at:
- **Elden Ring**: `%USERPROFILE%\AppData\Roaming\EldenRing\ER0000.sl2`
- **Seamless Coop**: `%USERPROFILE%\AppData\Roaming\EldenRing\[SteamID]\ER0000.co2`

## Mod Launcher Support

The application supports launching Elden Ring through mod launchers:

### ModEngine2 Example
1. **Game Executable**: `C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING\Game\ME2\modengine2_launcher.exe`
2. **Launch Arguments**: `-t er -c .\config_eldenring.toml`
3. **Working Directory**: Automatically set to the executable's directory

### Other Mod Launchers
- **Convergence**: Set executable to your convergence launcher
- **Custom Mods**: Any executable with custom arguments
- **Steam Integration**: Falls back to Steam if no custom executable is configured

## System Tray Features

The application runs in system tray mode with these features:
- **Right-click tray icon** - Context menu with quick actions
- **Double-click tray icon** - Show/hide main window
- **Background operation** - Monitors even when window is hidden
- **Minimize to tray** - Closing window minimizes to tray instead of exiting

## Configuration File

Settings are automatically saved to `config.json` in the same directory as the script. You can manually edit this file if needed.

### Configuration Structure

The `config.json` file contains the following settings:

```json
{
    "GameExecutable": "",
    "SaveFilePath": "C:\\Users\\YourUsername\\AppData\\Roaming\\EldenRing\\ER0000.sl2",
    "BackupFolder": "C:\\Users\\YourUsername\\Documents\\EldenRingBackups",
    "MaxBackups": 50,
    "MonitorMode": "FileChange",
    "TimerInterval": 300,
    "LaunchArguments": "",
    "Language": "en",
    "IsRunning": false
}
```

- **GameExecutable**: Path to Elden Ring executable or mod launcher (empty for Steam fallback)
- **SaveFilePath**: Path to your Elden Ring save file
- **BackupFolder**: Directory where compressed backups are stored
- **MaxBackups**: Maximum number of backup files to keep (default: 50)
- **MonitorMode**: "FileChange" or "TimerInterval"
- **TimerInterval**: Backup interval in seconds (when using timer mode)
- **LaunchArguments**: Command line arguments for the executable (e.g., mod launcher args)
- **Language**: Interface language code (e.g., "en", "es", "fr", "ja", "zh-CN", "ko")
- **IsRunning**: Whether monitoring is currently active

## Troubleshooting

- **"Save file not found"**: Ensure the save file path is correct and the file exists
- **"Backup folder not configured"**: Select a backup folder before starting monitoring
- **Permission errors**: Run PowerShell as Administrator if you encounter permission issues
- **File in use**: Elden Ring must be closed for file monitoring to work properly
- **Game won't launch**: Check that the executable path is correct and launch arguments are valid
- **No backups created**: Ensure monitoring is started and the save file path is correct
- **Compression issues**: Ensure the backup folder has write permissions
- **Multiple instances**: The application prevents multiple instances - close any existing ones first

## Safety Notes

- Always test with a copy of your save file first
- Keep multiple backup locations for important saves
- The application creates timestamped, compressed backups to avoid overwriting existing files
- Old backups are automatically cleaned up based on your maximum backup setting (default: 50)
- Zip compression reduces backup size by ~90% while maintaining full file integrity
- Backups are created with intelligent 10-second debouncing to prevent duplicate backups

## File Structure

```
EldenRingSaveBackup.ps1           # Main application with responsive UI
StartEldenRingBackup.bat          # Silent mode launcher (no console)
StartEldenRingBackup.vbs          # VBScript helper for silent mode
StartEldenRingBackup-Console.bat # Console mode launcher (with output)
config.json                       # Configuration file (auto-generated)
config.example.json               # Example configuration file
languages.json                    # Multi-language support file
README.md                         # This file
```

## License

This tool is provided as-is for personal use. Use at your own risk and always backup your important save files manually as well.
