# Elden Ring Save File Backup Tool - Unified System Tray Application
# PowerShell GUI Application with System Tray Integration

# Load Windows Forms assembly early for message boxes
Add-Type -AssemblyName System.Windows.Forms

# Prevent multiple instances from running
$mutexName = "EldenRingSaveBackup_SingleInstance"
$mutex = $null
try {
    $mutex = [System.Threading.Mutex]::new($false, $mutexName)
    
    # Try to acquire mutex with a short timeout to handle crashed instances
    if (-not $mutex.WaitOne(1000, $false)) {  # 1 second timeout
        $errorMessage = @"
Elden Ring Save Backup is already running. Only one instance is allowed.

Please close the existing instance before starting a new one.

If you believe no other instance is running, the previous instance may have crashed.

In this case, you can:
1. Wait 30 seconds for the system to release the mutex, or
2. Restart your computer to clear all mutexes, or
3. Use Task Manager to kill any remaining EldenRingSaveBackup processes

Alternatively, you can force start by running:
Get-Process | Where-Object {`$_.ProcessName -like '*EldenRing*'} | Stop-Process -Force
"@
        
        # Show console message
        Write-Host $errorMessage
        
        # Show GUI message box
        try {
            Write-Host "Attempting to show message box..."
            [System.Windows.Forms.MessageBox]::Show($errorMessage, "Elden Ring Save Backup - Instance Already Running", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            Write-Host "Message box should have appeared"
        } catch {
            # Fallback if MessageBox fails
            Write-Host "Could not show message box: $($_.Exception.Message)"
        }
        
        exit 1
    }
} catch {
    $errorMessage = "Error checking for existing instances: $($_.Exception.Message)`n`nThe application will continue, but multiple instances may be possible."
    
    # Show console message
    Write-Host $errorMessage
    
    # Show GUI message box
    try {
        [System.Windows.Forms.MessageBox]::Show($errorMessage, "Elden Ring Save Backup - Instance Check Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    } catch {
        # Fallback if MessageBox fails
        Write-Host "Could not show message box: $($_.Exception.Message)"
    }
    
    # Don't exit - continue with a warning
}

# Set console encoding for proper Unicode support - Stack Overflow solution
# Set UTF-8 encoding for proper Unicode support
$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding


# Set application encoding for proper Unicode support
try {
    [System.Text.Encoding]::Default = [System.Text.Encoding]::UTF8
} catch {
    # Default encoding is read-only, this is expected
}

# Function to create Unicode-compatible font
function New-UnicodeFont {
    param([string]$fontFamily = "Arial Unicode MS", [float]$size = 9, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular)
    
    try {
        # Try Arial Unicode MS first as it has the best Unicode support
        $fontFamilies = @("Arial Unicode MS", "Segoe UI", "Tahoma", "Lucida Sans Unicode", "Microsoft Sans Serif")
        
        foreach ($family in $fontFamilies) {
            try {
                $font = New-Object System.Drawing.Font($family, $size, $style, [System.Drawing.GraphicsUnit]::Point)
                return $font
            } catch {
                continue
            }
        }
        
        # Final fallback
        $font = New-Object System.Drawing.Font("Microsoft Sans Serif", $size, $style, [System.Drawing.GraphicsUnit]::Point)
        return $font
    } catch {
        # Ultimate fallback
        $font = New-Object System.Drawing.Font("Microsoft Sans Serif", $size, $style, [System.Drawing.GraphicsUnit]::Point)
        return $font
    }
}

# Function to ensure Unicode support for controls
function Set-UnicodeSupport {
    param([System.Windows.Forms.Control]$control)
    
    try {
        # Set Unicode-compatible properties
        $control.UseCompatibleTextRendering = $false
        $control.Font = New-UnicodeFont "Segoe UI" 9
        
        # Force refresh to ensure Unicode rendering
        $control.Invalidate()
        $control.Update()
        
        # Set text encoding if possible
        if ($control.GetType().Name -eq "TextBox" -or $control.GetType().Name -eq "ComboBox") {
            $control.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::UTF8.GetBytes($control.Text))
        }
    } catch {
        # Some properties may not be available in all .NET versions
    }
}

# Function to set Unicode text on controls with dynamic sizing
function Set-UnicodeText {
    param([System.Windows.Forms.Control]$control, [string]$text)
    
    try {
        # Direct assignment - let Windows Forms handle Unicode with proper font
        $control.Text = $text
        
        # Dynamic sizing for buttons and labels
        if ($control.GetType().Name -eq "Button" -or $control.GetType().Name -eq "Label") {
            # Measure the text to determine appropriate size
            $textSize = $control.CreateGraphics().MeasureString($text, $control.Font)
            $newWidth = [Math]::Max($textSize.Width + 40, 120) # Add more padding, minimum 120px
            
            # Only resize if the new width is significantly different
            if ($newWidth -gt $control.Width + 20 -or $newWidth -lt $control.Width - 20) {
                $control.Width = [Math]::Min($newWidth, 500) # Cap at 500px to prevent too wide
            }
        }
        
        # Force refresh
        $control.Invalidate()
        $control.Update()
        
        # Trigger responsive layout update after text changes
        if ($script:mainForm -and $script:mainForm.IsHandleCreated) {
            Update-ResponsiveLayout
        }
    } catch {
        # Fallback to direct assignment
        $control.Text = $text
    }
}


Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO

# Force Unicode support for Windows Forms - MUST be called before any Form is created
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# Set DPI awareness for better Unicode rendering
$code = @"
    [System.Runtime.InteropServices.DllImport("Shcore.dll")]
    public static extern int SetProcessDpiAwareness(int dpiAwarenessMode);
"@
$PInvoke = Add-Type -MemberDefinition $code -Name "PInvoke" -PassThru
$null = $PInvoke::SetProcessDpiAwareness(2)

# Set culture to support Unicode
try {
    [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture
    [System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::InvariantCulture
} catch {
    Write-Host "Note: Could not set culture for Unicode support"
}

# Force UTF-8 encoding for the entire application
try {
    [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [System.Console]::InputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
    Write-Host "Note: Could not set UTF-8 encoding"
}

# Enable HiDPI support
try {
    [System.Windows.Forms.Application]::SetHighDpiMode("PerMonitorV2")
} catch {
    # SetHighDpiMode not available in older .NET Framework versions
    Write-Host "Note: SetHighDpiMode not available - using fallback DPI support"
}

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# Set DPI awareness for better HiDPI support
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DpiHelper {
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")]
    public static extern bool SetProcessDpiAwareness(int awareness);
}
"@

try {
    [DpiHelper]::SetProcessDpiAwareness(2) # PerMonitorV2
} catch {
    try {
        [DpiHelper]::SetProcessDPIAware()
    } catch {
        # Fallback - continue without DPI awareness
    }
}

# Global variables
$script:config = @{
    GameExecutable = ""
    LaunchArguments = ""
    SaveFilePath = ""
    BackupFolder = ""
    MaxBackups = 10
    MonitorMode = "FileChange"  # "FileChange" or "Timer"
    TimerInterval = 300  # seconds
    IsRunning = $false
    Language = "en"
}
$script:mutex = $mutex  # Store mutex reference for cleanup

# Language system
$script:languages = @{}
$script:currentLanguage = "en"

# Log message tracking for translation
$script:logEntries = @()  # Array of hashtables: @{Timestamp, LanguageKey, Parameters}

# Load language files
function Import-Languages {
    try {
        $languagesPath = Join-Path $PSScriptRoot "languages.json"
        if (Test-Path $languagesPath) {
            $languagesJson = Get-Content $languagesPath -Raw | ConvertFrom-Json
            # Convert to hashtable for easier access
            $script:languages = @{}
            foreach ($key in $languagesJson.PSObject.Properties.Name) {
                $script:languages[$key] = $languagesJson.$key
            }
            Write-Host "Languages loaded: $($script:languages.Keys -join ', ')"
        } else {
            Write-Host "Warning: languages.json not found, using English only"
        }
    } catch {
        Write-Host "Error loading languages: $($_.Exception.Message)"
    }
}

# Get localized text
function Get-Text {
    param([string]$key, [object[]]$formatArgs = @())
    
    $text = $key  # Fallback to key name
    
    # Check current language first
    if ($script:languages.ContainsKey($script:currentLanguage)) {
        $langObj = $script:languages[$script:currentLanguage]
        if ($langObj.PSObject.Properties.Name -contains $key) {
            $text = $langObj.$key
        }
    }
    
    # Fallback to English if not found in current language
    if ($text -eq $key -and $script:languages.ContainsKey("en")) {
        $enObj = $script:languages["en"]
        if ($enObj.PSObject.Properties.Name -contains $key) {
            $text = $enObj.$key
        }
    }
    
    # Format with arguments if provided
    if ($formatArgs.Count -gt 0) {
        return $text -f $formatArgs
    }
    return $text
}

# Set language
function Set-Language {
    param([string]$languageCode)
    
    if ($script:languages.ContainsKey($languageCode)) {
        $script:currentLanguage = $languageCode
        $script:config.Language = $languageCode
        Write-Host "Language changed to: $languageCode"
        return $true
    } else {
        Write-Host "Language not supported: $languageCode"
        return $false
    }
}

# Refresh form text with current language - UPDATED FOR SECTIONED LAYOUT
function Update-FormText {
    if ($script:mainForm -and $script:mainForm.IsHandleCreated) {
        
        # Update form title
        $script:mainForm.Text = Get-Text "app_title"
        Write-Host "Updating form text for language: $script:currentLanguage"
        Write-Host "Form title updated to: $($script:mainForm.Text)"
        
        # Force refresh the form
        $script:mainForm.Refresh()
        
        # Update controls by searching through sections
        $controlsUpdated = 0
        
        # Update all controls in all sections
        $allSections = $script:mainForm.Controls | Where-Object { $_.Name -like "*Section" }
        foreach ($section in $allSections) {
            foreach ($control in $section.Controls) {
            $oldText = $control.Text
            $controlName = $control.Name
            
            # Apply Unicode support to all controls
            Set-UnicodeSupport $control
            
            # Map control names to language keys
            switch ($controlName) {
                "lblLanguage" {
                    Set-UnicodeText $control (Get-Text "language")
                    Set-LabelSize $control 500
                    Write-Host "Updated language label: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "lblGameExe" { 
                    Set-UnicodeText $control (Get-Text "game_executable")
                    Set-LabelSize $control 350
                    Write-Host "Updated game exe label: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "lblSaveFile" { 
                    Set-UnicodeText $control (Get-Text "save_file")
                    Set-LabelSize $control 350
                    Write-Host "Updated save file label: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "lblBackupFolder" { 
                    Set-UnicodeText $control (Get-Text "backup_folder")
                    Set-LabelSize $control 350
                    Write-Host "Updated backup folder label: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "lblMaxBackups" { 
                    Set-UnicodeText $control (Get-Text "number_of_backups")
                    Set-LabelSize $control 500
                    Write-Host "Updated max backups label: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "lblStatus" { 
                    Set-UnicodeText $control (Get-Text "status_ready")
                    Set-LabelSize $control 500
                    Write-Host "Updated status label: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "lblLastBackup" { 
                    Set-UnicodeText $control (Get-Text "last_backup_never")
                    Set-LabelSize $control 500
                    Write-Host "Updated last backup label: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "btnBrowseGameExe" { 
                    Set-UnicodeText $control (Get-Text "browse")
                    Write-Host "Updated browse game button: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "btnBrowseSaveFile" { 
                    Set-UnicodeText $control (Get-Text "browse")
                    Write-Host "Updated browse save button: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "btnBrowseBackupFolder" { 
                    Set-UnicodeText $control (Get-Text "browse")
                    Write-Host "Updated browse backup button: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "btnAutoDetectGameExe" { 
                    if ($script:toolTip) { $script:toolTip.SetToolTip($control, (Get-Text "auto_detect_tooltip_game")) }
                    Write-Host "Updated auto-detect game button tooltip"
                    $controlsUpdated++
                }
                "btnAutoDetectSaveFile" { 
                    if ($script:toolTip) { $script:toolTip.SetToolTip($control, (Get-Text "auto_detect_tooltip_save")) }
                    Write-Host "Updated auto-detect save button tooltip"
                    $controlsUpdated++
                }
                "btnStart" { 
                    Set-UnicodeText $control (Get-Text "start_monitoring")
                    Write-Host "Updated start button: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "btnStop" { 
                    Set-UnicodeText $control (Get-Text "stop_monitoring")
                    Write-Host "Updated stop button: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "btnBackupNow" { 
                    Set-UnicodeText $control (Get-Text "backup_now")
                    Write-Host "Updated backup now button: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "btnMinimize" { 
                    Set-UnicodeText $control (Get-Text "minimize_to_tray")
                    Write-Host "Updated minimize button: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "btnLaunchGame" { 
                    Set-UnicodeText $control (Get-Text "launch_elden_ring")
                    Write-Host "Updated launch button: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "chkExitToTray" { 
                    Set-UnicodeText $control (Get-Text "exit_to_tray")
                    Write-Host "Updated checkbox: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "lblMonitorMode" {
                    Set-UnicodeText $control (Get-Text "monitor_mode")
                    Set-LabelSize $control 200
                    Write-Host "Updated monitor mode label: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "radFileChange" {
                    Set-UnicodeText $control (Get-Text "file_change_detection")
                    Write-Host "Updated file change radio: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "radTimerInterval" {
                    Set-UnicodeText $control (Get-Text "timer_interval")
                    Write-Host "Updated timer interval radio: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "lblTimerIntervalSeconds" {
                    Set-UnicodeText $control (Get-Text "timer_interval_seconds")
                    Set-LabelSize $control 300
                    Write-Host "Updated timer interval seconds label: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                "btnHelp" {
                    Set-UnicodeText $control (Get-Text "help_button")
                    Write-Host "Updated help button: $oldText -> $($control.Text)"
                    $controlsUpdated++
                }
                }
            }
        }
        
        Write-Host "Updated $controlsUpdated controls"
        
        # Update responsive layout after text changes
        Update-ResponsiveLayout
        
        # Update system tray menu
        Update-SystemTrayMenu
        Write-Host "Form text update completed"
    } else {
        Write-Host "Form not ready for text update"
    }
}

# Update system tray menu with current language
function Update-SystemTrayMenu {
    if ($script:notifyIcon -and $script:notifyIcon.ContextMenuStrip) {
        $script:notifyIcon.Text = Get-Text "app_title"
        
        # Update menu items by name instead of text matching
        foreach ($item in $script:notifyIcon.ContextMenuStrip.Items) {
            if ($item.GetType().Name -eq "ToolStripMenuItem") {
                switch ($item.Name) {
                    "ShowMenuItem" { $item.Text = Get-Text "tray_show_window" }
                    "StartMenuItem" { $item.Text = Get-Text "tray_start_monitoring" }
                    "StopMenuItem" { $item.Text = Get-Text "tray_stop_monitoring" }
                    "BackupMenuItem" { $item.Text = Get-Text "tray_backup_now" }
                    "LaunchMenuItem" { $item.Text = Get-Text "tray_launch_game" }
                    "ExitMenuItem" { $item.Text = Get-Text "tray_exit" }
                }
            }
        }
    }
}

$script:fileWatcher = $null
$script:timer = $null
$script:lastBackupTime = $null
$script:mainForm = $null
$script:notifyIcon = $null
$script:cmbLanguage = $null

# Function to handle language change
function Switch-Language {
    param([int]$index)
    
    $languageCodes = @("en", "es", "fr", "ja", "zh-CN", "ko")
    if ($index -ge 0 -and $index -lt $languageCodes.Count) {
        $languageCode = $languageCodes[$index]
        
        # Set the language
        $script:currentLanguage = $languageCode
        $script:config.Language = $languageCode
        Write-Host "Switching to language: $languageCode (index: $index)"
        Write-Host "Previous language was: $script:currentLanguage"
        
        # Save the language preference
        Save-Config
        
        # Refresh all text on the form
        Update-FormText
        
        # Update log translation
        Update-LogTranslation
        
        # Update system tray menu with new language
        Update-SystemTrayMenu
        
        Write-Host "Language successfully changed to: $languageCode"
        Write-Host "Current language is now: $script:currentLanguage"
        return $true
    }
    return $false
}

# Create system tray icon
function New-SystemTrayIcon {
    $script:notifyIcon = New-Object System.Windows.Forms.NotifyIcon
    $script:notifyIcon.Text = Get-Text "app_title"
    $script:notifyIcon.Visible = $true
    
    # Set the system tray icon
    try {
        $iconPath = Join-Path $PSScriptRoot "er.ico"
        if (Test-Path $iconPath) {
            $script:notifyIcon.Icon = [System.Drawing.Icon]::FromHandle(([System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)).Handle)
        } else {
            $script:notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
        }
    } catch {
        Write-Host "Warning: Could not load tray icon from $iconPath, using default"
        $script:notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
    }
    
    # Create context menu
    $contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
    
    $showMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $showMenuItem.Name = "ShowMenuItem"
    $showMenuItem.Text = Get-Text "tray_show_window"
    $showMenuItem.Add_Click({
        Show-MainWindow
    })
    
    $startMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $startMenuItem.Name = "StartMenuItem"
    $startMenuItem.Text = Get-Text "tray_start_monitoring"
    $startMenuItem.Add_Click({
        Start-Monitoring
    })
    
    $stopMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $stopMenuItem.Name = "StopMenuItem"
    $stopMenuItem.Text = Get-Text "tray_stop_monitoring"
    $stopMenuItem.Add_Click({
        Stop-Monitoring
    })
    
    $backupMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $backupMenuItem.Name = "BackupMenuItem"
    $backupMenuItem.Text = Get-Text "tray_backup_now"
    $backupMenuItem.Add_Click({
        Backup-SaveFile
    })
    
    $launchMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $launchMenuItem.Name = "LaunchMenuItem"
    $launchMenuItem.Text = Get-Text "tray_launch_game"
    $launchMenuItem.Add_Click({
        Start-EldenRing
    })
    
    $separator = New-Object System.Windows.Forms.ToolStripSeparator
    
    $exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $exitMenuItem.Name = "ExitMenuItem"
    $exitMenuItem.Text = Get-Text "tray_exit"
    $exitMenuItem.Add_Click({
        Exit-Application
    })
    
    $contextMenu.Items.AddRange(@(
        $showMenuItem,
        $separator,
        $startMenuItem,
        $stopMenuItem,
        $backupMenuItem,
        $launchMenuItem,
        $separator,
        $exitMenuItem
    ))
    
    $script:notifyIcon.ContextMenuStrip = $contextMenu
    
    # Double-click to show window
    $script:notifyIcon.Add_DoubleClick({
        Write-Log -languageKey "log_tray_double_clicked"
        Show-MainWindow
    })
}

# Create main form
function New-MainForm {
    # Create main form with proper sizing to prevent clipping
    $script:mainForm = [System.Windows.Forms.Form] @{
        AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
        ClientSize = [System.Drawing.Size]::new(1400, 1100)  # Increased height for launch arguments field
        MinimumSize = [System.Drawing.Size]::new(1200, 900)  # Increased minimum height for launch arguments
        StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
        FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
        MaximizeBox = $true
        MinimizeBox = $true
        BackColor = [System.Drawing.Color]::White
        Text = Get-Text "app_title"
        Font = New-UnicodeFont "Arial Unicode MS" 9
    }
    
    # Set the form icon
    try {
        $iconPath = Join-Path $PSScriptRoot "er.ico"
        if (Test-Path $iconPath) {
            $script:mainForm.Icon = [System.Drawing.Icon]::FromHandle(([System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)).Handle)
        }
    } catch {
        Write-Host "Warning: Could not load icon from $iconPath"
    }
    
    # Apply Unicode support to the main form
    Set-UnicodeSupport $script:mainForm
    
    # Simple layout - no complex responsive system
    
    # Handle form closing - check if user wants to exit to tray or minimize
    $script:mainForm.Add_FormClosing({
        param($formSender, $e)
        # Check if the close button was clicked (not programmatic)
        if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing) {
            # Check if "Exit to Tray" checkbox is checked
            $controlSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "ControlSection" }
            if ($controlSection) {
                $chkExitToTray = $controlSection.Controls | Where-Object { $_.Name -eq "chkExitToTray" }
            if ($chkExitToTray -and $chkExitToTray.Checked) {
                # User wants to minimize to tray, cancel the close and minimize instead
                $e.Cancel = $true
                Hide-MainWindow
            } else {
                # User wants to actually exit, show confirmation with proper translation
                $result = [System.Windows.Forms.MessageBox]::Show(
                    (Get-Text "exit_confirm_message"),
                    (Get-Text "exit_confirm_title"),
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Question
                )
                
                if ($result -eq [System.Windows.Forms.DialogResult]::No) {
                    $e.Cancel = $true
                } else {
                    # User confirmed exit
                    $script:exitApplication = $true
                    $script:mainForm.Dispose()
                    [System.Windows.Forms.Application]::Exit()
                    }
                }
            }
        }
    })
    
    # Add form resize event handler for responsive layout
    $script:mainForm.Add_Resize({
        Update-ResponsiveLayout
    })
}

# Helper function to calculate responsive positions and sizes
function Get-ResponsiveLayout {
    $formWidth = $script:mainForm.ClientSize.Width
    $formHeight = $script:mainForm.ClientSize.Height
    
    # Base dimensions for 1920x1080
    $baseWidth = 1920
    $baseHeight = 1080
    
    # Calculate scale factors
    $scaleX = $formWidth / $baseWidth
    $scaleY = $formHeight / $baseHeight
    $scale = [Math]::Min($scaleX, $scaleY)  # Use the smaller scale to maintain proportions
    
    # Responsive values
    $padding = [Math]::Max(20, [int](20 * $scale))
    $sectionSpacing = [Math]::Max(30, [int](40 * $scale))
    $controlHeight = [Math]::Max(25, [int](30 * $scale))
    $buttonWidth = [Math]::Max(80, [int](100 * $scale))
    $buttonHeight = [Math]::Max(25, [int](30 * $scale))
    
    return @{
        FormWidth = $formWidth
        FormHeight = $formHeight
        Scale = $scale
        Padding = $padding
        SectionSpacing = $sectionSpacing
        ControlHeight = $controlHeight
        ButtonWidth = $buttonWidth
        ButtonHeight = $buttonHeight
    }
}

# Function to create section panels with proper grouping and responsive design
function New-SectionPanel {
    param(
        [string]$name,
        [string]$title,
        [int]$x,
        [int]$y,
        [int]$width,
        [int]$height,
        [bool]$isResponsive = $true
    )
    
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Name = $name
    $panel.Location = New-Object System.Drawing.Point($x, $y)
    $panel.Size = New-Object System.Drawing.Size($width, $height)
    $panel.BorderStyle = [System.Windows.Forms.BorderStyle]::None  # No visible border
    $panel.BackColor = [System.Drawing.Color]::Transparent  # Transparent background
    $panel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $panel.AutoScroll = $false  # Disable auto-scroll to prevent clipping
    
    # Add invisible title label for organization (not visible to user)
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $title
    $titleLabel.Name = "${name}_Title"
    $titleLabel.Location = New-Object System.Drawing.Point(0, 0)
    $titleLabel.Size = New-Object System.Drawing.Size(1, 1)
    $titleLabel.Font = New-UnicodeFont "Segoe UI" 1
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $titleLabel.ForeColor = [System.Drawing.Color]::Transparent
    $titleLabel.Visible = $false  # Completely invisible
    $titleLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $panel.Controls.Add($titleLabel)
    
    return $panel
}

# Function to update all control positions when form is resized - NEW SECTIONED LAYOUT
function Update-ResponsiveLayout {
    if (-not $script:mainForm -or -not $script:mainForm.IsHandleCreated) { 
        Write-Host "Form not ready for layout update"
        return 
    }
    
    Write-Host "Updating responsive layout - Form: $($script:mainForm.ClientSize.Width)x$($script:mainForm.ClientSize.Height)"
    
    # Get form dimensions and calculate responsive values
    $formWidth = $script:mainForm.ClientSize.Width
    $formHeight = $script:mainForm.ClientSize.Height
    
    # Calculate responsive font size based on form size - cap at 12 to prevent clipping
    $baseFontSize = [Math]::Max(7, [Math]::Min(9, [int](($formWidth + $formHeight) / 250)))  # Smaller base font
    $buttonFontSize = [Math]::Max(7, [Math]::Min(8, [int](($formWidth + $formHeight) / 300)))  # Smaller button font
    
    # Responsive layout constants with better spacing to prevent clipping
    $padding = [Math]::Max(12, [int](($formWidth * 0.015)))  # 1.5% of form width, minimum 12px
    $sectionSpacing = [Math]::Max(8, [int](($formHeight * 0.01)))  # 1% of form height, minimum 8px - reduced spacing
    $controlHeight = [Math]::Max(24, [int](($formHeight * 0.03)))  # 3% of form height, minimum 24px
    $buttonHeight = [Math]::Max(28, [int](($formHeight * 0.035)))  # 3.5% of form height, minimum 28px
    $internalPadding = [Math]::Max(8, [int](($formWidth * 0.01)))  # 1% of form width, minimum 8px
    
    # Calculate section dimensions with better spacing
    $availableWidth = ($formWidth - ($padding * 2))
    $sectionWidth = $availableWidth
    $textboxWidth = [Math]::Max(200, ($sectionWidth - 160))  # Leave room for browse button with more margin
    $buttonWidth = [Math]::Max(100, [Math]::Min(130, (($sectionWidth - ($internalPadding * 8)) / 4)))  # Better button sizing with proper spacing
    
    # Current Y position for sections
    $currentY = $padding
    
    # Calculate responsive section heights based on form size and content
    # Ensure all sections fit within the form with proper spacing
    $totalAvailableHeight = ($formHeight - ($padding * 2))
    $totalSpacing = ($sectionSpacing * 6)  # 6 gaps between 7 sections
    
    # Calculate balanced heights for content sections (not log)
    $languageSectionHeight = [Math]::Max(60, ($controlHeight + 30))
    $gameSectionHeight = [Math]::Max(120, (($controlHeight + 8) * 4 + 30))  # Increased for launch arguments
    $saveSectionHeight = [Math]::Max(70, (($controlHeight + 8) * 2 + 30))
    $backupSectionHeight = [Math]::Max(220, (($controlHeight + 8) * 5 + 60))  # Reduced height for smaller controls
    $controlSectionHeight = [Math]::Max(70, (($buttonHeight + 8) * 2 + 30))
    $statusSectionHeight = [Math]::Max(60, (($controlHeight + 8) * 2 + 30))
    
    # Calculate used height for fixed sections
    $fixedSectionsHeight = $languageSectionHeight + $gameSectionHeight + $saveSectionHeight + $backupSectionHeight + $controlSectionHeight + $statusSectionHeight
    
    # Calculate remaining height for log section with responsive minimum
    $remainingHeight = $totalAvailableHeight - $fixedSectionsHeight - $totalSpacing
    $logSectionHeight = [Math]::Max(100, $remainingHeight)  # Minimum 100px for log section, but use remaining space
    
    Write-Host "Section heights - Lang:$languageSectionHeight Game:$gameSectionHeight Save:$saveSectionHeight Backup:$backupSectionHeight Control:$controlSectionHeight Status:$statusSectionHeight Log:$logSectionHeight"
    Write-Host "Total used height: $($fixedSectionsHeight + $totalSpacing), Remaining: $remainingHeight, Form height: $formHeight"
    
    # Update Language Section
    $languageSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "LanguageSection" }
    if ($languageSection) {
        $languageSection.Location = New-Object System.Drawing.Point($padding, $currentY)
        $languageSection.Size = New-Object System.Drawing.Size($sectionWidth, $languageSectionHeight)
        Update-LanguageSectionLayout $languageSection $internalPadding $controlHeight $textboxWidth $baseFontSize
        $currentY += ($languageSectionHeight + $sectionSpacing)
    }
    
    # Update Game Section
    $gameSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "GameSection" }
    if ($gameSection) {
        $gameSection.Location = New-Object System.Drawing.Point($padding, $currentY)
        $gameSection.Size = New-Object System.Drawing.Size($sectionWidth, $gameSectionHeight)
        Update-GameSectionLayout $gameSection $internalPadding $controlHeight $textboxWidth $baseFontSize $buttonFontSize
        $currentY += ($gameSectionHeight + $sectionSpacing)
    }
    
    # Update Save Section
    $saveSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "SaveSection" }
    if ($saveSection) {
        $saveSection.Location = New-Object System.Drawing.Point($padding, $currentY)
        $saveSection.Size = New-Object System.Drawing.Size($sectionWidth, $saveSectionHeight)
        Update-SaveSectionLayout $saveSection $internalPadding $controlHeight $textboxWidth $baseFontSize $buttonFontSize
        $currentY += ($saveSectionHeight + $sectionSpacing)
    }
    
    # Update Backup Section
    $backupSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "BackupSection" }
    if ($backupSection) {
        $backupSection.Location = New-Object System.Drawing.Point($padding, $currentY)
        $backupSection.Size = New-Object System.Drawing.Size($sectionWidth, $backupSectionHeight)
        Update-BackupSectionLayout $backupSection $internalPadding $controlHeight $textboxWidth $baseFontSize $buttonFontSize
        $currentY += ($backupSectionHeight + $sectionSpacing)
    }
    
    # Update Control Section
    $controlSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "ControlSection" }
    if ($controlSection) {
        $controlSection.Location = New-Object System.Drawing.Point($padding, $currentY)
        $controlSection.Size = New-Object System.Drawing.Size($sectionWidth, $controlSectionHeight)
        Update-ControlSectionLayout $controlSection $internalPadding $buttonHeight $buttonWidth $buttonFontSize $baseFontSize
        $currentY += ($controlSectionHeight + $sectionSpacing)
    }
    
    # Update Status Section
    $statusSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "StatusSection" }
    if ($statusSection) {
        $statusSection.Location = New-Object System.Drawing.Point($padding, $currentY)
        $statusSection.Size = New-Object System.Drawing.Size($sectionWidth, $statusSectionHeight)
        Update-StatusSectionLayout $statusSection $internalPadding $controlHeight $baseFontSize
        $currentY += ($statusSectionHeight + $sectionSpacing)
    }
    
    # Update Log Section - uses calculated responsive height
    $logSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "LogSection" }
    if ($logSection) {
        $logSection.Location = New-Object System.Drawing.Point($padding, $currentY)
        $logSection.Size = New-Object System.Drawing.Size($sectionWidth, $logSectionHeight)
        Update-LogSectionLayout $logSection $internalPadding $baseFontSize
    }
}

# Individual section layout functions for responsive design
function Update-LanguageSectionLayout {
    param($section, $padding, $controlHeight, $textboxWidth, $baseFontSize)
    
    # Write-Host "Updating Language Section Layout"
    $lblLanguage = $section.Controls | Where-Object { $_.Name -eq "lblLanguage" }
    $cmbLanguage = $section.Controls | Where-Object { $_.Name -eq "cmbLanguage" }
    $btnHelp = $section.Controls | Where-Object { $_.Name -eq "btnHelp" }
    
    if ($lblLanguage) {
        $lblLanguage.Location = New-Object System.Drawing.Point($padding, 25)
        $lblLanguage.Font = New-UnicodeFont "Segoe UI" $baseFontSize
        
        # Recalculate width based on new font size
        Set-LabelSize $lblLanguage 300
    }
    if ($cmbLanguage) {
        # Position combo box relative to label width
        $labelRight = ($lblLanguage.Location.X + $lblLanguage.Width + 10)  # 10px gap
        $cmbLanguage.Location = New-Object System.Drawing.Point($labelRight, 25)
        $cmbLanguage.Size = New-Object System.Drawing.Size(150, $controlHeight)
        $cmbLanguage.Font = New-UnicodeFont "Segoe UI" $baseFontSize
    }
    if ($btnHelp) {
        # Position help button next to combo box
        $comboRight = ($cmbLanguage.Location.X + $cmbLanguage.Width + 10)  # 10px gap
        $btnHelp.Location = New-Object System.Drawing.Point($comboRight, 25)
        $btnHelp.Size = New-Object System.Drawing.Size(80, $controlHeight)
        $btnHelp.Font = New-UnicodeFont "Segoe UI" $baseFontSize
    }
}

function Update-GameSectionLayout {
    param($section, $padding, $controlHeight, $textboxWidth, $baseFontSize, $buttonFontSize)
    
    $lblGameExe = $section.Controls | Where-Object { $_.Name -eq "lblGameExe" }
    $txtGameExe = $section.Controls | Where-Object { $_.Name -eq "txtGameExe" }
    $btnBrowseGameExe = $section.Controls | Where-Object { $_.Name -eq "btnBrowseGameExe" }
    $btnAutoDetectGameExe = $section.Controls | Where-Object { $_.Name -eq "btnAutoDetectGameExe" }
    $lblLaunchArguments = $section.Controls | Where-Object { $_.Name -eq "lblLaunchArguments" }
    $txtLaunchArguments = $section.Controls | Where-Object { $_.Name -eq "txtLaunchArguments" }
    
    if ($lblGameExe) {
        $lblGameExe.Location = New-Object System.Drawing.Point($padding, 25)
        $lblGameExe.Font = New-UnicodeFont "Segoe UI" $baseFontSize
        
        # Use max text width across all languages
        $maxTextWidth = Get-MaxTextWidth "game_executable" "Segoe UI" $baseFontSize
        Set-LabelSize $lblGameExe $maxTextWidth
    }
    if ($txtGameExe) {
        $txtGameExe.Location = New-Object System.Drawing.Point($padding, (25 + $controlHeight + 15))  # More space between label and textbox
        $txtGameExe.Size = New-Object System.Drawing.Size($textboxWidth, $controlHeight)
        $txtGameExe.Font = New-UnicodeFont "Segoe UI" $baseFontSize
    }
    if ($btnAutoDetectGameExe) {
        # Position auto-detect button to the left of browse button
        $btnAutoDetectGameExe.Location = New-Object System.Drawing.Point(($padding + $textboxWidth + 10), (25 + $controlHeight + 15))
        $btnAutoDetectGameExe.Size = New-Object System.Drawing.Size(30, $controlHeight)
        $btnAutoDetectGameExe.Font = New-UnicodeFont "Segoe UI" $buttonFontSize
    }
    if ($btnBrowseGameExe) {
        # Position browse button to the right of auto-detect button
        $btnBrowseGameExe.Location = New-Object System.Drawing.Point(($padding + $textboxWidth + 45), (25 + $controlHeight + 15))  # 30px + 15px gap
        $btnBrowseGameExe.Size = New-Object System.Drawing.Size(100, $controlHeight)
        $btnBrowseGameExe.Font = New-UnicodeFont "Segoe UI" $buttonFontSize
    }
    
    # Launch Arguments Label
    if ($lblLaunchArguments) {
        $lblLaunchArguments.Location = New-Object System.Drawing.Point($padding, (25 + $controlHeight + 15 + $controlHeight + 15))  # Below the game exe row
        $lblLaunchArguments.Font = New-UnicodeFont "Segoe UI" $baseFontSize
        
        # Use max text width across all languages
        $maxTextWidth = Get-MaxTextWidth "launch_arguments" "Segoe UI" $baseFontSize
        Set-LabelSize $lblLaunchArguments $maxTextWidth
    }
    
    # Launch Arguments Text Box
    if ($txtLaunchArguments) {
        $txtLaunchArguments.Location = New-Object System.Drawing.Point($padding, (25 + $controlHeight + 15 + $controlHeight + 15 + $controlHeight + 15))  # Below the launch arguments label
        $txtLaunchArguments.Size = New-Object System.Drawing.Size($textboxWidth, $controlHeight)
        $txtLaunchArguments.Font = New-UnicodeFont "Segoe UI" $baseFontSize
        $txtLaunchArguments.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)  # Very light grey background
    }
}

function Update-SaveSectionLayout {
    param($section, $padding, $controlHeight, $textboxWidth, $baseFontSize, $buttonFontSize)
    
    $lblSaveFile = $section.Controls | Where-Object { $_.Name -eq "lblSaveFile" }
    $txtSaveFile = $section.Controls | Where-Object { $_.Name -eq "txtSaveFile" }
    $btnBrowseSaveFile = $section.Controls | Where-Object { $_.Name -eq "btnBrowseSaveFile" }
    $btnAutoDetectSaveFile = $section.Controls | Where-Object { $_.Name -eq "btnAutoDetectSaveFile" }
    
    if ($lblSaveFile) {
        $lblSaveFile.Location = New-Object System.Drawing.Point($padding, 25)
        $lblSaveFile.Font = New-UnicodeFont "Segoe UI" $baseFontSize
        
        # Use max text width across all languages
        $maxTextWidth = Get-MaxTextWidth "save_file" "Segoe UI" $baseFontSize
        Set-LabelSize $lblSaveFile $maxTextWidth
    }
    if ($txtSaveFile) {
        $txtSaveFile.Location = New-Object System.Drawing.Point($padding, (25 + $controlHeight + 15))  # More space between label and textbox
        $txtSaveFile.Size = New-Object System.Drawing.Size($textboxWidth, $controlHeight)
        $txtSaveFile.Font = New-UnicodeFont "Segoe UI" $baseFontSize
    }
    if ($btnAutoDetectSaveFile) {
        # Position auto-detect button to the left of browse button
        $btnAutoDetectSaveFile.Location = New-Object System.Drawing.Point(($padding + $textboxWidth + 10), (25 + $controlHeight + 15))
        $btnAutoDetectSaveFile.Size = New-Object System.Drawing.Size(30, $controlHeight)
        $btnAutoDetectSaveFile.Font = New-UnicodeFont "Segoe UI" $buttonFontSize
    }
    if ($btnBrowseSaveFile) {
        # Position browse button to the right of auto-detect button
        $btnBrowseSaveFile.Location = New-Object System.Drawing.Point(($padding + $textboxWidth + 45), (25 + $controlHeight + 15))  # 30px + 15px gap
        $btnBrowseSaveFile.Size = New-Object System.Drawing.Size(100, $controlHeight)
        $btnBrowseSaveFile.Font = New-UnicodeFont "Segoe UI" $buttonFontSize
    }
}

function Update-BackupSectionLayout {
    param($section, $padding, $controlHeight, $textboxWidth, $baseFontSize, $buttonFontSize)
    
    $lblBackupFolder = $section.Controls | Where-Object { $_.Name -eq "lblBackupFolder" }
    $txtBackupFolder = $section.Controls | Where-Object { $_.Name -eq "txtBackupFolder" }
    $btnBrowseBackupFolder = $section.Controls | Where-Object { $_.Name -eq "btnBrowseBackupFolder" }
    $lblMaxBackups = $section.Controls | Where-Object { $_.Name -eq "lblMaxBackups" }
    $numMaxBackups = $section.Controls | Where-Object { $_.Name -eq "numMaxBackups" }
    $lblMonitorMode = $section.Controls | Where-Object { $_.Name -eq "lblMonitorMode" }
    $radFileChange = $section.Controls | Where-Object { $_.Name -eq "radFileChange" }
    $radTimerInterval = $section.Controls | Where-Object { $_.Name -eq "radTimerInterval" }
    $lblTimerIntervalSeconds = $section.Controls | Where-Object { $_.Name -eq "lblTimerIntervalSeconds" }
    $numTimerInterval = $section.Controls | Where-Object { $_.Name -eq "numTimerInterval" }
    
    # Backup Folder - Full width on its own line
    if ($lblBackupFolder) {
        $lblBackupFolder.Location = New-Object System.Drawing.Point($padding, 25)
        $lblBackupFolder.Font = New-UnicodeFont "Segoe UI" $baseFontSize
        $maxTextWidth = Get-MaxTextWidth "backup_folder" "Segoe UI" $baseFontSize
        Set-LabelSize $lblBackupFolder $maxTextWidth
    }
    if ($txtBackupFolder) {
        $txtBackupFolder.Location = New-Object System.Drawing.Point($padding, (25 + $controlHeight + 15))  # More space between label and textbox
        $txtBackupFolder.Size = New-Object System.Drawing.Size($textboxWidth, $controlHeight)  # Full width like other text boxes
        $txtBackupFolder.Font = New-UnicodeFont "Segoe UI" $baseFontSize
    }
    if ($btnBrowseBackupFolder) {
        $btnBrowseBackupFolder.Location = New-Object System.Drawing.Point(($padding + $textboxWidth + 10), (25 + $controlHeight + 15))  # More space between label and textbox
        $btnBrowseBackupFolder.Size = New-Object System.Drawing.Size(100, $controlHeight)
        $btnBrowseBackupFolder.Font = New-UnicodeFont "Segoe UI" $buttonFontSize
    }
    
    # Calculate horizontal layout for backup settings - give backup method much more space
    $availableWidth = $section.Width - ($padding * 2)
    
    # Give backup method section 70% of space, number of backups gets 30%
    $leftHalfWidth = [Math]::Round($availableWidth * 0.3)  # 30% for number of backups
    $rightHalfWidth = $availableWidth - $leftHalfWidth - 20  # 70% for backup method (minus gap)
    $rightHalfX = $padding + $leftHalfWidth + 20  # 20px gap between sections
    
    Write-Host "DEBUG: Backup section layout - Available width: $availableWidth, Left half: $leftHalfWidth, Right half starts at: $rightHalfX"
    
    # Left half: Number of Backups - with much more vertical space
    if ($lblMaxBackups) {
        $lblMaxBackups.Location = New-Object System.Drawing.Point($padding, (25 + ($controlHeight + 5) * 2 + 20))
        $lblMaxBackups.Font = New-UnicodeFont "Segoe UI" $baseFontSize
        $maxTextWidth = Get-MaxTextWidth "number_of_backups" "Segoe UI" $baseFontSize
        $labelMaxWidth = [Math]::Min($maxTextWidth, $leftHalfWidth)
        Set-LabelSize $lblMaxBackups $labelMaxWidth  # Use max text width or available space
    }
    if ($numMaxBackups) {
        $labelRight = ($lblMaxBackups.Location.X + $lblMaxBackups.Width + 10)
        $numMaxBackups.Location = New-Object System.Drawing.Point($labelRight, (25 + ($controlHeight + 5) * 2 + 20))
        $numMaxBackups.Size = New-Object System.Drawing.Size(60, $controlHeight)
        $numMaxBackups.Font = New-UnicodeFont "Segoe UI" $baseFontSize
    }
    
    # Right half: Backup Method - use full available width
    $rightHalfWidth = $availableWidth - $leftHalfWidth - $gapBetweenHalves
    
    if ($lblMonitorMode) {
        $lblMonitorMode.Location = New-Object System.Drawing.Point($rightHalfX, (25 + ($controlHeight + 5) * 2 + 20))
        $lblMonitorMode.Font = New-UnicodeFont "Segoe UI" $baseFontSize
        $maxTextWidth = Get-MaxTextWidth "monitor_mode" "Segoe UI" $baseFontSize
        $labelMaxWidth = [Math]::Min($maxTextWidth, ($rightHalfWidth - 20))
        Set-LabelSize $lblMonitorMode $labelMaxWidth  # Use max text width or available space
    }
    # Radio buttons on the SAME horizontal line - positioned relative to label
    if ($lblMonitorMode -and $radFileChange) {
        $labelRight = $lblMonitorMode.Location.X + $lblMonitorMode.Width + 10
        $radFileChange.Location = New-Object System.Drawing.Point($labelRight, (25 + ($controlHeight + 5) * 2 + 20))
        $radFileChange.Font = New-UnicodeFont "Segoe UI" $baseFontSize
        
        # Calculate available space for radio buttons - now we have much more space
        $availableForRadios = $rightHalfX + $rightHalfWidth - $radFileChange.Location.X - 20
        
        # Calculate max width needed for radio button text across all languages
        $maxFileChangeWidth = Get-MaxTextWidth "file_change_detection" "Segoe UI" $baseFontSize
        $maxTimerWidth = Get-MaxTextWidth "timer_interval" "Segoe UI" $baseFontSize
        $maxRadioWidth = [Math]::Max($maxFileChangeWidth, $maxTimerWidth)
        
        # Use the smaller of: max text width or available space divided by 2, but ensure minimum 150px
        $radioWidth = [Math]::Max(150, [Math]::Min($maxRadioWidth, $availableForRadios / 2 - 20))
        $radFileChange.Size = New-Object System.Drawing.Size($radioWidth, 22)  # Smaller, more reasonable height
        $radFileChange.Visible = $true
        Write-Host "DEBUG: radFileChange positioned at $($radFileChange.Location), Size: $($radFileChange.Size), Available space: $availableForRadios"
    }
    if ($radFileChange -and $radTimerInterval) {
        $firstRadioRight = $radFileChange.Location.X + $radFileChange.Width + 10
        $radTimerInterval.Location = New-Object System.Drawing.Point($firstRadioRight, (25 + ($controlHeight + 5) * 2 + 20))  # Relative to first radio
        $radTimerInterval.Font = New-UnicodeFont "Segoe UI" $baseFontSize
        $radTimerInterval.Size = New-Object System.Drawing.Size($radioWidth, 22)  # Same width and height as first radio
        $radTimerInterval.Visible = $true
        Write-Host "DEBUG: radTimerInterval positioned at $($radTimerInterval.Location), Size: $($radTimerInterval.Size)"
    }
    
    # Timer Interval controls - BELOW the radio buttons with proper spacing
    if ($lblTimerIntervalSeconds) {
        $lblTimerIntervalSeconds.Location = New-Object System.Drawing.Point($rightHalfX, (25 + ($controlHeight + 5) * 2 + 60))  # Well below radio buttons
        $lblTimerIntervalSeconds.Font = New-UnicodeFont "Segoe UI" $baseFontSize
        $maxTextWidth = Get-MaxTextWidth "timer_interval_seconds" "Segoe UI" $baseFontSize
        $labelMaxWidth = [Math]::Min($maxTextWidth, ($rightHalfWidth - 20))
        Set-LabelSize $lblTimerIntervalSeconds $labelMaxWidth  # Use max text width or available space
    }
    if ($lblTimerIntervalSeconds -and $numTimerInterval) {
        $labelRight = $lblTimerIntervalSeconds.Location.X + $lblTimerIntervalSeconds.Width + 10  # Relative to label
        $numTimerInterval.Location = New-Object System.Drawing.Point($labelRight, (25 + ($controlHeight + 5) * 2 + 60))  # Same Y as label
        $numTimerInterval.Size = New-Object System.Drawing.Size(120, $controlHeight)
        $numTimerInterval.Font = New-UnicodeFont "Segoe UI" $baseFontSize
    }
    
    Write-Host "DEBUG: Right half width: $rightHalfWidth, Timer label at: $($lblTimerIntervalSeconds.Location.X), Timer control at: $($numTimerInterval.Location.X)"
}

function Update-ControlSectionLayout {
    param($section, $padding, $buttonHeight, $buttonWidth, $buttonFontSize, $baseFontSize)
    
    $btnStart = $section.Controls | Where-Object { $_.Name -eq "btnStart" }
    $btnStop = $section.Controls | Where-Object { $_.Name -eq "btnStop" }
    $btnBackupNow = $section.Controls | Where-Object { $_.Name -eq "btnBackupNow" }
    $btnMinimize = $section.Controls | Where-Object { $_.Name -eq "btnMinimize" }
    $btnLaunchGame = $section.Controls | Where-Object { $_.Name -eq "btnLaunchGame" }
    $chkExitToTray = $section.Controls | Where-Object { $_.Name -eq "chkExitToTray" }
    
    # Calculate button spacing to prevent clipping with better margins
    $buttonSpacing = [Math]::Max(12, [int](($section.Width - ($buttonWidth * 4) - ($padding * 2)) / 3))
    
    # First row of buttons
    if ($btnStart) {
        $btnStart.Location = New-Object System.Drawing.Point($padding, 25)
        $btnStart.Size = New-Object System.Drawing.Size($buttonWidth, $buttonHeight)
        $btnStart.Font = New-UnicodeFont "Segoe UI" $buttonFontSize
    }
    if ($btnStop) {
        $btnStop.Location = New-Object System.Drawing.Point(($padding + $buttonWidth + $buttonSpacing), 25)
        $btnStop.Size = New-Object System.Drawing.Size($buttonWidth, $buttonHeight)
        $btnStop.Font = New-UnicodeFont "Segoe UI" $buttonFontSize
    }
    if ($btnBackupNow) {
        $btnBackupNow.Location = New-Object System.Drawing.Point(($padding + (($buttonWidth + $buttonSpacing) * 2)), 25)
        $btnBackupNow.Size = New-Object System.Drawing.Size($buttonWidth, $buttonHeight)
        $btnBackupNow.Font = New-UnicodeFont "Segoe UI" $buttonFontSize
    }
    if ($btnMinimize) {
        $btnMinimize.Location = New-Object System.Drawing.Point(($padding + (($buttonWidth + $buttonSpacing) * 3)), 25)
        $btnMinimize.Size = New-Object System.Drawing.Size($buttonWidth, $buttonHeight)
        $btnMinimize.Font = New-UnicodeFont "Segoe UI" $buttonFontSize
    }
    
    # Second row - Launch game and checkbox
    if ($btnLaunchGame) {
        $btnLaunchGame.Location = New-Object System.Drawing.Point($padding, (25 + $buttonHeight + 5))
        $btnLaunchGame.Size = New-Object System.Drawing.Size([Math]::Min(150, ($buttonWidth * 1.5)), $buttonHeight)
        $btnLaunchGame.Font = New-UnicodeFont "Segoe UI" $buttonFontSize
    }
    if ($chkExitToTray) {
        $chkExitToTray.Location = New-Object System.Drawing.Point(($padding + [Math]::Min(180, ($buttonWidth * 1.5) + 15)), (25 + $buttonHeight + 8))
        $chkExitToTray.Size = New-Object System.Drawing.Size([Math]::Min(400, ($section.Width - ($padding * 2) - [Math]::Min(180, ($buttonWidth * 1.5) + 15))), 25)
        $chkExitToTray.Font = New-UnicodeFont "Segoe UI" $baseFontSize
    }
}

function Update-StatusSectionLayout {
    param($section, $padding, $controlHeight, $baseFontSize)
    
    $lblStatus = $section.Controls | Where-Object { $_.Name -eq "lblStatus" }
    $lblLastBackup = $section.Controls | Where-Object { $_.Name -eq "lblLastBackup" }
    
    if ($lblStatus) {
        $lblStatus.Location = New-Object System.Drawing.Point($padding, 25)
        $lblStatus.Font = New-UnicodeFont "Segoe UI" $baseFontSize
        
        # Recalculate width based on new font size
        Set-LabelSize $lblStatus 500
    }
    if ($lblLastBackup) {
        $lblLastBackup.Location = New-Object System.Drawing.Point($padding, (25 + $controlHeight + 5))
        $lblLastBackup.Font = New-UnicodeFont "Segoe UI" $baseFontSize
        
        # Recalculate width based on new font size
        Set-LabelSize $lblLastBackup 500
    }
}

function Update-LogSectionLayout {
    param($section, $padding, $baseFontSize)
    
    # Write-Host "DEBUG: Update-LogSectionLayout called"
    $txtLog = $section.Controls | Where-Object { $_.Name -eq "txtLog" }
    if ($txtLog) {
        # Write-Host "DEBUG: txtLog found in LogSection, updating layout"
        # Preserve existing text content
        $existingText = $txtLog.Text
        
        $txtLog.Location = New-Object System.Drawing.Point($padding, 25)
        $txtLog.Size = New-Object System.Drawing.Size(($section.Width - ($padding * 2)), [Math]::Max(80, ($section.Height - 40)))
        $txtLog.Font = New-UnicodeFont "Consolas" $baseFontSize
        $txtLog.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
        $txtLog.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
        $txtLog.Multiline = $true
        $txtLog.ReadOnly = $true
        $txtLog.Visible = $true
        
        # Restore the text content
        $txtLog.Text = $existingText
        
        Write-Host "DEBUG: txtLog positioned at $($txtLog.Location) with size $($txtLog.Size)"
        Write-Host "DEBUG: txtLog properties - Visible: $($txtLog.Visible), Enabled: $($txtLog.Enabled), Text length: $($txtLog.Text.Length)"
    } else {
        # Write-Host "DEBUG: txtLog not found in LogSection during layout update"
    }
}

function New-FormControls {
    Write-Host "Creating form controls with sectioned layout and responsive design"
    
    # Create all sections first
    New-AllSections
    
    # Add all controls to their respective sections
    Add-ControlsToSections
    
    # Set up event handlers
    Set-EventHandlers
    
    # Apply initial responsive layout immediately since form is already shown
    Update-ResponsiveLayout
    
    # Force a refresh to ensure controls are visible
    $script:mainForm.Refresh()
}

function New-AllSections {
    Write-Host "Creating section panels..."
    
    # Language Section
    $languageSection = New-SectionPanel "LanguageSection" "Language Settings" 0 0 800 60
    $script:mainForm.Controls.Add($languageSection)
    
    # Game Section
    $gameSection = New-SectionPanel "GameSection" "Game Configuration" 0 0 800 100
    $script:mainForm.Controls.Add($gameSection)
    
    # Save Section
    $saveSection = New-SectionPanel "SaveSection" "Save File Settings" 0 0 800 100
    $script:mainForm.Controls.Add($saveSection)
    
    # Backup Section
    $backupSection = New-SectionPanel "BackupSection" "Backup Configuration" 0 0 800 120
    $script:mainForm.Controls.Add($backupSection)
    
    # Control Section
    $controlSection = New-SectionPanel "ControlSection" "Application Controls" 0 0 800 80
    $script:mainForm.Controls.Add($controlSection)
    
    # Status Section
    $statusSection = New-SectionPanel "StatusSection" "Status Information" 0 0 800 60
    $script:mainForm.Controls.Add($statusSection)
    
    # Log Section
    $logSection = New-SectionPanel "LogSection" "Application Log" 0 0 800 200
    $script:mainForm.Controls.Add($logSection)
}

function Add-ControlsToSections {
    Write-Host "Adding controls to sections..."
    
    # Language Section Controls
    $languageSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "LanguageSection" }
    
    # Shared tooltip for the whole form
    if (-not $script:toolTip) {
        $script:toolTip = New-Object System.Windows.Forms.ToolTip
    }
    
    $lblLanguage = New-Object System.Windows.Forms.Label
    $lblLanguage.Text = "Language:"
    $lblLanguage.Name = "lblLanguage"
    $lblLanguage.Font = New-UnicodeFont "Segoe UI" 9
    $lblLanguage.Size = New-Object System.Drawing.Size(120, 35)  # Increased height to prevent clipping
    $languageSection.Controls.Add($lblLanguage)

    $script:cmbLanguage = New-Object System.Windows.Forms.ComboBox
    $script:cmbLanguage.Name = "cmbLanguage"
    $script:cmbLanguage.DropDownStyle = "DropDownList"
    $script:cmbLanguage.Font = New-UnicodeFont "Segoe UI" 9
    $script:cmbLanguage.Items.AddRange(@("English", "Español", "Français", "日本語", "中文", "한국어"))
    $languageSection.Controls.Add($script:cmbLanguage)
    
        # Help button next to language combo box
        $btnHelp = New-Object System.Windows.Forms.Button
        $btnHelp.Name = "btnHelp"
        $btnHelp.Text = Get-Text "help_button"
        $btnHelp.Font = New-UnicodeFont "Segoe UI" 9
        # Calculate width for all languages - "도움말" (Korean) is the longest
        $btnHelp.Size = New-Object System.Drawing.Size(80, 25)
        $btnHelp.UseVisualStyleBackColor = $true
        $languageSection.Controls.Add($btnHelp)
    
    # Set initial language selection
    $languageCodes = @("en", "es", "fr", "ja", "zh-CN", "ko")
    $initialIndex = 0
    if ($script:config.Language) {
        $index = $languageCodes.IndexOf($script:config.Language)
        if ($index -ge 0) { $initialIndex = $index }
    }
    $script:cmbLanguage.SelectedIndex = $initialIndex
    
    # Game Section Controls
    $gameSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "GameSection" }
    
    $lblGameExe = New-Object System.Windows.Forms.Label
    $lblGameExe.Name = "lblGameExe"
    $lblGameExe.Text = Get-Text "game_executable"
    $lblGameExe.Font = New-UnicodeFont "Segoe UI" 9
    $lblGameExe.Size = New-Object System.Drawing.Size(180, 35)  # Increased height to prevent clipping
    $gameSection.Controls.Add($lblGameExe)

    $txtGameExe = New-Object System.Windows.Forms.TextBox
    $txtGameExe.Name = "txtGameExe"
    $txtGameExe.ReadOnly = $true
    $txtGameExe.Font = New-UnicodeFont "Segoe UI" 9
    $gameSection.Controls.Add($txtGameExe)

    $btnBrowseGameExe = New-Object System.Windows.Forms.Button
    $btnBrowseGameExe.Name = "btnBrowseGameExe"
    $btnBrowseGameExe.Text = Get-Text "browse"
    $btnBrowseGameExe.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    $btnBrowseGameExe.Font = New-UnicodeFont "Segoe UI" 9
    $gameSection.Controls.Add($btnBrowseGameExe)

    # Auto-detect Game Executable Button
    $btnAutoDetectGameExe = New-Object System.Windows.Forms.Button
    $btnAutoDetectGameExe.Name = "btnAutoDetectGameExe"
    $btnAutoDetectGameExe.Text = "🔍"
    $btnAutoDetectGameExe.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    $btnAutoDetectGameExe.Font = New-UnicodeFont "Segoe UI" 9
    $btnAutoDetectGameExe.Size = New-Object System.Drawing.Size(30, 23)  # Small square button
    $gameSection.Controls.Add($btnAutoDetectGameExe)
    $script:toolTip.SetToolTip($btnAutoDetectGameExe, (Get-Text "auto_detect_tooltip_game"))

    # Launch Arguments Label
    $lblLaunchArguments = New-Object System.Windows.Forms.Label
    $lblLaunchArguments.Name = "lblLaunchArguments"
    $lblLaunchArguments.Text = Get-Text "launch_arguments"
    $lblLaunchArguments.Font = New-UnicodeFont "Segoe UI" 9
    $lblLaunchArguments.Size = New-Object System.Drawing.Size(200, 24)
    $gameSection.Controls.Add($lblLaunchArguments)

    # Launch Arguments Text Box
    $txtLaunchArguments = New-Object System.Windows.Forms.TextBox
    $txtLaunchArguments.Name = "txtLaunchArguments"
    $txtLaunchArguments.Font = New-UnicodeFont "Segoe UI" 9
    $txtLaunchArguments.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)  # Very light grey background
    $gameSection.Controls.Add($txtLaunchArguments)

    # Save Section Controls
    $saveSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "SaveSection" }
    
    $lblSaveFile = New-Object System.Windows.Forms.Label
    $lblSaveFile.Name = "lblSaveFile"
    $lblSaveFile.Text = Get-Text "save_file"
    $lblSaveFile.Font = New-UnicodeFont "Segoe UI" 9
    $lblSaveFile.Size = New-Object System.Drawing.Size(180, 35)  # Increased height to prevent clipping
    $saveSection.Controls.Add($lblSaveFile)

    $txtSaveFile = New-Object System.Windows.Forms.TextBox
    $txtSaveFile.Name = "txtSaveFile"
    $txtSaveFile.ReadOnly = $true
    $txtSaveFile.Font = New-UnicodeFont "Segoe UI" 9
    $saveSection.Controls.Add($txtSaveFile)

    $btnBrowseSaveFile = New-Object System.Windows.Forms.Button
    $btnBrowseSaveFile.Name = "btnBrowseSaveFile"
    $btnBrowseSaveFile.Text = Get-Text "browse"
    $btnBrowseSaveFile.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    $btnBrowseSaveFile.Font = New-UnicodeFont "Segoe UI" 9
    $saveSection.Controls.Add($btnBrowseSaveFile)

    # Auto-detect Save File Button
    $btnAutoDetectSaveFile = New-Object System.Windows.Forms.Button
    $btnAutoDetectSaveFile.Name = "btnAutoDetectSaveFile"
    $btnAutoDetectSaveFile.Text = "🔍"
    $btnAutoDetectSaveFile.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    $btnAutoDetectSaveFile.Font = New-UnicodeFont "Segoe UI" 9
    $btnAutoDetectSaveFile.Size = New-Object System.Drawing.Size(30, 23)  # Small square button
    $saveSection.Controls.Add($btnAutoDetectSaveFile)
    $script:toolTip.SetToolTip($btnAutoDetectSaveFile, (Get-Text "auto_detect_tooltip_save"))

    # Backup Section Controls
    $backupSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "BackupSection" }
    
    $lblBackupFolder = New-Object System.Windows.Forms.Label
    $lblBackupFolder.Name = "lblBackupFolder"
    $lblBackupFolder.Text = Get-Text "backup_folder"
    $lblBackupFolder.Font = New-UnicodeFont "Segoe UI" 9
    $lblBackupFolder.Size = New-Object System.Drawing.Size(120, 35)  # Increased height to prevent clipping
    $backupSection.Controls.Add($lblBackupFolder)

    $txtBackupFolder = New-Object System.Windows.Forms.TextBox
    $txtBackupFolder.Name = "txtBackupFolder"
    $txtBackupFolder.ReadOnly = $true
    $txtBackupFolder.Font = New-UnicodeFont "Segoe UI" 9
    $backupSection.Controls.Add($txtBackupFolder)

    $btnBrowseBackupFolder = New-Object System.Windows.Forms.Button
    $btnBrowseBackupFolder.Name = "btnBrowseBackupFolder"
    $btnBrowseBackupFolder.Text = Get-Text "browse"
    $btnBrowseBackupFolder.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    $btnBrowseBackupFolder.Font = New-UnicodeFont "Segoe UI" 9
    $backupSection.Controls.Add($btnBrowseBackupFolder)

    $lblMaxBackups = New-Object System.Windows.Forms.Label
    $lblMaxBackups.Name = "lblMaxBackups"
    $lblMaxBackups.Text = Get-Text "number_of_backups"
    $lblMaxBackups.Font = New-UnicodeFont "Segoe UI" 9
    $lblMaxBackups.Size = New-Object System.Drawing.Size(200, 35)  # Increased height to prevent clipping
    $backupSection.Controls.Add($lblMaxBackups)

    $numMaxBackups = New-Object System.Windows.Forms.NumericUpDown
    $numMaxBackups.Name = "numMaxBackups"
    $numMaxBackups.Minimum = 1
    $numMaxBackups.Maximum = 100
    $numMaxBackups.Value = $script:config.MaxBackups
    $numMaxBackups.Font = New-UnicodeFont "Segoe UI" 9
    $backupSection.Controls.Add($numMaxBackups)

    # Monitor Mode Controls
    $lblMonitorMode = New-Object System.Windows.Forms.Label
    $lblMonitorMode.Name = "lblMonitorMode"
    $lblMonitorMode.Text = Get-Text "monitor_mode"
    $lblMonitorMode.Font = New-UnicodeFont "Segoe UI" 9
    $lblMonitorMode.Size = New-Object System.Drawing.Size(120, 35)  # Increased height to prevent clipping
    $backupSection.Controls.Add($lblMonitorMode)

    $radFileChange = New-Object System.Windows.Forms.RadioButton
    $radFileChange.Name = "radFileChange"
    $radFileChange.Text = "File Change Detection"
    $radFileChange.Checked = ($script:config.MonitorMode -eq "FileChange")
    $radFileChange.Font = New-UnicodeFont "Segoe UI" 9
    # Size will be set by Update-BackupSectionLayout
    $radFileChange.Visible = $true
    $radFileChange.Enabled = $true
    $backupSection.Controls.Add($radFileChange)
    Write-Host "DEBUG: radFileChange created with text '$($radFileChange.Text)', size $($radFileChange.Size), added to backupSection"

    $radTimerInterval = New-Object System.Windows.Forms.RadioButton
    $radTimerInterval.Name = "radTimerInterval"
    $radTimerInterval.Text = Get-Text "timer_interval"
    $radTimerInterval.Checked = ($script:config.MonitorMode -eq "Timer")
    $radTimerInterval.Font = New-UnicodeFont "Segoe UI" 9
    # Size will be set by Update-BackupSectionLayout
    $backupSection.Controls.Add($radTimerInterval)

    $lblTimerIntervalSeconds = New-Object System.Windows.Forms.Label
    $lblTimerIntervalSeconds.Name = "lblTimerIntervalSeconds"
    $lblTimerIntervalSeconds.Text = Get-Text "timer_interval_seconds"
    $lblTimerIntervalSeconds.Font = New-UnicodeFont "Segoe UI" 9
    $lblTimerIntervalSeconds.Size = New-Object System.Drawing.Size(200, 35)  # Increased height to prevent clipping
    $backupSection.Controls.Add($lblTimerIntervalSeconds)

    $numTimerInterval = New-Object System.Windows.Forms.NumericUpDown
    $numTimerInterval.Name = "numTimerInterval"
    $numTimerInterval.Minimum = 10
    $numTimerInterval.Maximum = 3600
    $numTimerInterval.Value = $script:config.TimerInterval
    $numTimerInterval.Font = New-UnicodeFont "Segoe UI" 9
    $backupSection.Controls.Add($numTimerInterval)

    # Control Section Controls
    $controlSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "ControlSection" }
    
    $btnStart = New-Object System.Windows.Forms.Button
    $btnStart.Name = "btnStart"
    $btnStart.Text = Get-Text "start_monitoring"
    $btnStart.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    $btnStart.Font = New-UnicodeFont "Segoe UI" 8  # Smaller font for two-line text
    $btnStart.Size = New-Object System.Drawing.Size(120, 28)  # Smaller, more reasonable size
    $controlSection.Controls.Add($btnStart)

    $btnStop = New-Object System.Windows.Forms.Button
    $btnStop.Name = "btnStop"
    $btnStop.Text = Get-Text "stop_monitoring"
    $btnStop.Enabled = $false
    $btnStop.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    $btnStop.Font = New-UnicodeFont "Segoe UI" 8  # Smaller font for two-line text
    $btnStop.Size = New-Object System.Drawing.Size(120, 28)  # Smaller, more reasonable size
    $controlSection.Controls.Add($btnStop)

    $btnBackupNow = New-Object System.Windows.Forms.Button
    $btnBackupNow.Name = "btnBackupNow"
    $btnBackupNow.Text = Get-Text "backup_now"
    $btnBackupNow.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    $btnBackupNow.Font = New-UnicodeFont "Segoe UI" 8  # Smaller font for two-line text
    $btnBackupNow.Size = New-Object System.Drawing.Size(90, 28)  # Smaller, more reasonable size
    $controlSection.Controls.Add($btnBackupNow)

    $btnMinimize = New-Object System.Windows.Forms.Button
    $btnMinimize.Name = "btnMinimize"
    $btnMinimize.Text = Get-Text "minimize_to_tray"
    $btnMinimize.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    $btnMinimize.Font = New-UnicodeFont "Segoe UI" 8  # Smaller font for two-line text
    $btnMinimize.Size = New-Object System.Drawing.Size(110, 28)  # Smaller, more reasonable size
    $controlSection.Controls.Add($btnMinimize)

    $btnLaunchGame = New-Object System.Windows.Forms.Button
    $btnLaunchGame.Name = "btnLaunchGame"
    $btnLaunchGame.Text = Get-Text "launch_elden_ring"
    $btnLaunchGame.BackColor = [System.Drawing.Color]::LightGreen
    $btnLaunchGame.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    $btnLaunchGame.Font = New-UnicodeFont "Segoe UI" 8 Bold  # Smaller font for two-line text
    $btnLaunchGame.Size = New-Object System.Drawing.Size(120, 28)  # Smaller, more reasonable size
    $controlSection.Controls.Add($btnLaunchGame)

    $chkExitToTray = New-Object System.Windows.Forms.CheckBox
    $chkExitToTray.Name = "chkExitToTray"
    $chkExitToTray.Text = Get-Text "exit_to_tray"
    $chkExitToTray.Checked = $true
    $chkExitToTray.Font = New-UnicodeFont "Segoe UI" 9
    $controlSection.Controls.Add($chkExitToTray)

    # Status Section Controls
    $statusSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "StatusSection" }
    
    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Name = "lblStatus"
    $lblStatus.Text = Get-Text "status_ready"
    $lblStatus.Font = New-UnicodeFont "Segoe UI" 9
    $lblStatus.Size = New-Object System.Drawing.Size(200, 35)  # Increased height to prevent clipping
    $statusSection.Controls.Add($lblStatus)

    $lblLastBackup = New-Object System.Windows.Forms.Label
    $lblLastBackup.Name = "lblLastBackup"
    $lblLastBackup.Text = Get-Text "last_backup_never"
    $lblLastBackup.Font = New-UnicodeFont "Segoe UI" 9
    $lblLastBackup.Size = New-Object System.Drawing.Size(200, 35)  # Increased height to prevent clipping
    $statusSection.Controls.Add($lblLastBackup)

    # Log Section Controls
    $logSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "LogSection" }
    if ($logSection) {
        Write-Host "DEBUG: LogSection found, creating txtLog control"
    $txtLog = New-Object System.Windows.Forms.TextBox
    $txtLog.Name = "txtLog"
    $txtLog.Multiline = $true
    $txtLog.ScrollBars = "Vertical"
    $txtLog.ReadOnly = $true
    $txtLog.Font = New-UnicodeFont "Consolas" 9
        $txtLog.Text = "=== " + (Get-Text "app_title") + " ===`r`n" + (Get-Text "log_app_started") + "`r`n"
        $logSection.Controls.Add($txtLog)
        
        # Add initial log entries to tracking array
        $script:logEntries = @()
        $initialEntry = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            LanguageKey = "log_app_started"
            Parameters = @()
            OriginalMessage = ""
        }
        $script:logEntries += $initialEntry
        
        Write-Host "DEBUG: txtLog control added to LogSection with initial text"
        Write-Host "DEBUG: txtLog properties - Visible: $($txtLog.Visible), Enabled: $($txtLog.Enabled), Text length: $($txtLog.Text.Length)"
    } else {
        Write-Host "DEBUG: LogSection not found when creating txtLog control"
    }
}

function Set-EventHandlers {
    Write-Host "Setting up event handlers..."
    
    # Get controls for event handlers
    $gameSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "GameSection" }
    $saveSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "SaveSection" }
    $backupSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "BackupSection" }
    $controlSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "ControlSection" }
    
    # Browse button events
    Write-Host "DEBUG: Looking for browse buttons..."
    Write-Host "DEBUG: gameSection found: $($gameSection -ne $null)"
    if ($gameSection) {
        Write-Host "DEBUG: gameSection controls:"
        $gameSection.Controls | ForEach-Object { Write-Host "  - $($_.Name): $($_.GetType().Name)" }
    }
    
    $btnBrowseGameExe = $gameSection.Controls | Where-Object { $_.Name -eq "btnBrowseGameExe" }
    Write-Host "DEBUG: btnBrowseGameExe found: $($btnBrowseGameExe -ne $null)"
    if ($btnBrowseGameExe) {
        $btnBrowseGameExe.Add_Click({
        try {
            $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $openFileDialog.Filter = "Executable Files (*.exe)|*.exe|All Files (*.*)|*.*"
            $openFileDialog.Title = "Select Elden Ring Executable"
            
            if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                Write-Host "File selected: $($openFileDialog.FileName)"
                # Use global form reference instead of local variable
                $gameSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "GameSection" }
                $txtGameExe = $gameSection.Controls | Where-Object { $_.Name -eq "txtGameExe" }
                Write-Host "Found txtGameExe control: $($txtGameExe -ne $null)"
                if ($txtGameExe) {
                    $txtGameExe.Text = $openFileDialog.FileName
                    $script:config.GameExecutable = $openFileDialog.FileName
                    Write-Host "Updated config.GameExecutable to: $($script:config.GameExecutable)"
                    Write-Log (Get-Text "log_game_executable_selected") -Parameters @($openFileDialog.FileName)
                    Save-Config
                    Write-Host "Config saved successfully"
                } else {
                    Write-Host "Error: Could not find txtGameExe control"
                    Write-Host "Available controls in gameSection:"
                    $gameSection.Controls | ForEach-Object { Write-Host "  - $($_.Name): $($_.GetType().Name)" }
                }
            }
        } catch {
            Write-Host "Error in browse game exe: $($_.Exception.Message)"
        }
        })
    } else {
        Write-Host "Warning: btnBrowseGameExe not found"
    }

    # Auto-detect Game Executable Button
    $btnAutoDetectGameExe = $gameSection.Controls | Where-Object { $_.Name -eq "btnAutoDetectGameExe" }
    Write-Host "DEBUG: btnAutoDetectGameExe found: $($btnAutoDetectGameExe -ne $null)"
    if ($btnAutoDetectGameExe) {
        $btnAutoDetectGameExe.Add_Click({
        try {
            Write-Host "Auto-detecting game executables..."
            $executables = Find-EldenRingGameExecutable
            
            if ($executables.Count -eq 0) {
                [System.Windows.Forms.MessageBox]::Show(
                    (Get-Text "auto_detect_no_game_executable"),
                    (Get-Text "auto_detect_game_executable"),
                    "OK",
                    "Information"
                )
            } elseif ($executables.Count -eq 1) {
                # Auto-select the only executable
                $selectedExe = $executables[0]
                $gameSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "GameSection" }
                $txtGameExe = $gameSection.Controls | Where-Object { $_.Name -eq "txtGameExe" }
                if ($txtGameExe) {
                    $txtGameExe.Text = $selectedExe.Path
                    $script:config.GameExecutable = $selectedExe.Path
                    Write-Log (Get-Text "auto_detect_game_executable_found") -Parameters @($selectedExe.Path)
                    Save-Config
                }
            } else {
                # Show selection dialog
                $selectedExe = Show-SelectionDialog -title (Get-Text "auto_detect_game_executable") -message (Get-Text "auto_detect_multiple_game_executables") -items $executables -displayProperty "Path"
                if ($selectedExe) {
                    $gameSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "GameSection" }
                    $txtGameExe = $gameSection.Controls | Where-Object { $_.Name -eq "txtGameExe" }
                    if ($txtGameExe) {
                        $txtGameExe.Text = $selectedExe.Path
                        $script:config.GameExecutable = $selectedExe.Path
                        Write-Log (Get-Text "auto_detect_game_executable_found") -Parameters @($selectedExe.Path)
                        Save-Config
                    }
                }
            }
        } catch {
            Write-Host "Error in auto-detect game executable: $($_.Exception.Message)"
        }
        })
    } else {
        Write-Host "Warning: btnAutoDetectGameExe not found"
    }

    $btnBrowseSaveFile = $saveSection.Controls | Where-Object { $_.Name -eq "btnBrowseSaveFile" }
    Write-Host "DEBUG: btnBrowseSaveFile found: $($btnBrowseSaveFile -ne $null)"
    if ($btnBrowseSaveFile) {
        $btnBrowseSaveFile.Add_Click({
        try {
            $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $openFileDialog.Filter = "All Save Files (*.sl2;*.co2)|*.sl2;*.co2|Elden Ring Save Files (*.sl2)|*.sl2|Seamless Coop Files (*.co2)|*.co2|All Files (*.*)|*.*"
            $openFileDialog.Title = "Select Elden Ring Save File"
            
            if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                Write-Host "Save file selected: $($openFileDialog.FileName)"
                # Use global form reference instead of local variable
                $saveSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "SaveSection" }
                $txtSaveFile = $saveSection.Controls | Where-Object { $_.Name -eq "txtSaveFile" }
                Write-Host "Found txtSaveFile control: $($txtSaveFile -ne $null)"
                if ($txtSaveFile) {
                    $txtSaveFile.Text = $openFileDialog.FileName
                    $script:config.SaveFilePath = $openFileDialog.FileName
                    Write-Host "Updated config.SaveFilePath to: $($script:config.SaveFilePath)"
                    Write-Log (Get-Text "log_save_file_selected") -Parameters @($openFileDialog.FileName)
                    Save-Config
                    Write-Host "Config saved successfully"
                } else {
                    Write-Host "Error: Could not find txtSaveFile control"
                    Write-Host "Available controls in saveSection:"
                    $saveSection.Controls | ForEach-Object { Write-Host "  - $($_.Name): $($_.GetType().Name)" }
                }
            }
        } catch {
            Write-Host "Error in browse save file: $($_.Exception.Message)"
        }
        })
    } else {
        Write-Host "Warning: btnBrowseSaveFile not found"
    }

    # Auto-detect Save File Button
    $btnAutoDetectSaveFile = $saveSection.Controls | Where-Object { $_.Name -eq "btnAutoDetectSaveFile" }
    Write-Host "DEBUG: btnAutoDetectSaveFile found: $($btnAutoDetectSaveFile -ne $null)"
    if ($btnAutoDetectSaveFile) {
        $btnAutoDetectSaveFile.Add_Click({
        try {
            Write-Host "Auto-detecting save files..."
            $saveFiles = Find-EldenRingSaveFiles
            
            if ($saveFiles.Count -eq 0) {
                [System.Windows.Forms.MessageBox]::Show(
                    (Get-Text "auto_detect_no_save_files"),
                    (Get-Text "auto_detect_save_file"),
                    "OK",
                    "Information"
                )
            } elseif ($saveFiles.Count -eq 1) {
                # Auto-select the only save file
                $selectedFile = $saveFiles[0]
                $saveSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "SaveSection" }
                $txtSaveFile = $saveSection.Controls | Where-Object { $_.Name -eq "txtSaveFile" }
                if ($txtSaveFile) {
                    $txtSaveFile.Text = $selectedFile.Path
                    $script:config.SaveFilePath = $selectedFile.Path
                    Write-Log (Get-Text "auto_detect_save_file_found") -Parameters @($selectedFile.Path)
                    Save-Config
                }
            } else {
                # Show selection dialog
                $selectedFile = Show-SelectionDialog -title (Get-Text "auto_detect_save_file") -message (Get-Text "auto_detect_multiple_save_files") -items $saveFiles -displayProperty "Path"
                if ($selectedFile) {
                    $saveSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "SaveSection" }
                    $txtSaveFile = $saveSection.Controls | Where-Object { $_.Name -eq "txtSaveFile" }
                    if ($txtSaveFile) {
                        $txtSaveFile.Text = $selectedFile.Path
                        $script:config.SaveFilePath = $selectedFile.Path
                        Write-Log (Get-Text "auto_detect_save_file_found") -Parameters @($selectedFile.Path)
                        Save-Config
                    }
                }
            }
        } catch {
            Write-Host "Error in auto-detect save file: $($_.Exception.Message)"
        }
        })
    } else {
        Write-Host "Warning: btnAutoDetectSaveFile not found"
    }

    $btnBrowseBackupFolder = $backupSection.Controls | Where-Object { $_.Name -eq "btnBrowseBackupFolder" }
    Write-Host "DEBUG: btnBrowseBackupFolder found: $($btnBrowseBackupFolder -ne $null)"
    if ($btnBrowseBackupFolder) {
        $btnBrowseBackupFolder.Add_Click({
        try {
            $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $folderBrowserDialog.Description = "Select Backup Folder"
            
            if ($folderBrowserDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                Write-Host "Backup folder selected: $($folderBrowserDialog.SelectedPath)"
                # Use global form reference instead of local variable
                $backupSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "BackupSection" }
                $txtBackupFolder = $backupSection.Controls | Where-Object { $_.Name -eq "txtBackupFolder" }
                Write-Host "Found txtBackupFolder control: $($txtBackupFolder -ne $null)"
                if ($txtBackupFolder) {
                    $txtBackupFolder.Text = $folderBrowserDialog.SelectedPath
                    $script:config.BackupFolder = $folderBrowserDialog.SelectedPath
                    Write-Host "Updated config.BackupFolder to: $($script:config.BackupFolder)"
                    Write-Log (Get-Text "log_backup_folder_selected") -Parameters @($folderBrowserDialog.SelectedPath)
                    Save-Config
                    Write-Host "Config saved successfully"
                } else {
                    Write-Host "Error: Could not find txtBackupFolder control"
                    Write-Host "Available controls in backupSection:"
                    $backupSection.Controls | ForEach-Object { Write-Host "  - $($_.Name): $($_.GetType().Name)" }
                }
            }
        } catch {
            Write-Host "Error in browse backup folder: $($_.Exception.Message)"
        }
        })
    } else {
        Write-Host "Warning: btnBrowseBackupFolder not found"
    }

    # Launch Arguments Text Box Event
    $txtLaunchArguments = $gameSection.Controls | Where-Object { $_.Name -eq "txtLaunchArguments" }
    Write-Host "DEBUG: txtLaunchArguments found: $($txtLaunchArguments -ne $null)"
    if ($txtLaunchArguments) {
        $txtLaunchArguments.Add_TextChanged({
            # Use global form reference to find the control
            $gameSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "GameSection" }
            $txtLaunchArguments = $gameSection.Controls | Where-Object { $_.Name -eq "txtLaunchArguments" }
            Write-Host "DEBUG: Launch arguments text changed to: $($txtLaunchArguments.Text)"
            $script:config.LaunchArguments = $txtLaunchArguments.Text
            Save-Config
            Write-Host "Launch arguments updated: $($script:config.LaunchArguments)"
        })
        Write-Host "DEBUG: Launch arguments event handler added successfully"
    } else {
        Write-Host "DEBUG: Warning - txtLaunchArguments not found for event handler"
    }

    # Control button events
    $btnStart = $controlSection.Controls | Where-Object { $_.Name -eq "btnStart" }
    $btnStart.Add_Click({ Start-Monitoring })

    $btnStop = $controlSection.Controls | Where-Object { $_.Name -eq "btnStop" }
    $btnStop.Add_Click({ Stop-Monitoring })

    $btnBackupNow = $controlSection.Controls | Where-Object { $_.Name -eq "btnBackupNow" }
    $btnBackupNow.Add_Click({ Backup-SaveFile })

    $btnMinimize = $controlSection.Controls | Where-Object { $_.Name -eq "btnMinimize" }
    $btnMinimize.Add_Click({ Hide-MainWindow })

    $btnLaunchGame = $controlSection.Controls | Where-Object { $_.Name -eq "btnLaunchGame" }
    $btnLaunchGame.Add_Click({ Start-EldenRing })

    # Language change event
    $script:cmbLanguage.Add_SelectedIndexChanged({
        try {
            $selectedLanguage = $script:cmbLanguage.SelectedIndex
            if ($null -ne $selectedLanguage -and $selectedLanguage -ge 0) {
                Switch-Language $selectedLanguage
            }
        } catch {
            Write-Host "Error in language change: $($_.Exception.Message)"
        }
    })

    # Help button click event
    $languageSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "LanguageSection" }
    $btnHelp = $languageSection.Controls | Where-Object { $_.Name -eq "btnHelp" }
    if ($btnHelp) {
        $btnHelp.Add_Click({
            Show-HelpDialog
        })
    } else {
        Write-Host "DEBUG: Help button not found in language section"
    }

    # Config change events
    $numMaxBackups = $backupSection.Controls | Where-Object { $_.Name -eq "numMaxBackups" }
    $numMaxBackups.Add_ValueChanged({
        # Re-fetch the control to ensure we have the right scope
        $backupSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "BackupSection" }
        $numMaxBackups = $backupSection.Controls | Where-Object { $_.Name -eq "numMaxBackups" }
        if ($numMaxBackups) {
            $script:config.MaxBackups = $numMaxBackups.Value
            Save-Config
            Write-Host "DEBUG: MaxBackups updated to: $($script:config.MaxBackups)"
        }
    })

    # Monitor mode radio button events
    $radFileChange = $backupSection.Controls | Where-Object { $_.Name -eq "radFileChange" }
    $radFileChange.Add_CheckedChanged({
        if ($radFileChange.Checked) {
            $script:config.MonitorMode = "FileChange"
            Save-Config
        }
    })

    $radTimerInterval = $backupSection.Controls | Where-Object { $_.Name -eq "radTimerInterval" }
    $radTimerInterval.Add_CheckedChanged({
        if ($radTimerInterval.Checked) {
            $script:config.MonitorMode = "Timer"
            Save-Config
        }
    })

    # Timer interval change event
    $numTimerInterval = $backupSection.Controls | Where-Object { $_.Name -eq "numTimerInterval" }
    $numTimerInterval.Add_ValueChanged({
        $script:config.TimerInterval = $numTimerInterval.Value
        Save-Config
    })
}

# Window management functions
function Show-MainWindow {
    if ($script:mainForm) {
        try {
            $script:mainForm.Show()
            $script:mainForm.WindowState = "Normal"
            $script:mainForm.ShowInTaskbar = $true
            $script:mainForm.BringToFront()
            $script:mainForm.Activate()
            $script:mainForm.Focus()
            Write-Log -languageKey "log_window_shown"
        }
        catch {
            Write-Log -languageKey "log_error_showing_window" -Parameters @($_.Exception.Message)
        }
    } else {
        Write-Log "Error: Main form not found"
    }
}

function Hide-MainWindow {
    if ($script:mainForm) {
        $script:mainForm.WindowState = "Minimized"
        $script:mainForm.ShowInTaskbar = $false
        Write-Log -languageKey "log_window_hidden"
    }
}

# Auto-detection functions
function Find-EldenRingSaveFiles {
    Write-Host "Auto-detecting Elden Ring save files..."
    
    $saveFiles = @()
    $eldenRingPath = Join-Path $env:USERPROFILE "AppData\Roaming\EldenRing"
    
    if (Test-Path $eldenRingPath) {
        # Look for Steam ID folders (numeric folders)
        $steamFolders = Get-ChildItem -Path $eldenRingPath -Directory | Where-Object { $_.Name -match '^\d+$' }
        
        foreach ($folder in $steamFolders) {
            $saveFile = Join-Path $folder.FullName "ER0000.sl2"
            if (Test-Path $saveFile) {
                $saveFileObj = [PSCustomObject]@{
                    Path = $saveFile
                    SteamID = $folder.Name
                    LastModified = (Get-Item $saveFile).LastWriteTime
                }
                $saveFiles += $saveFileObj
                Write-Host "DEBUG: Added save file: $($saveFileObj.Path)"
            }
        }
    }
    
    # Sort by last modified date (most recent first)
    $saveFiles = $saveFiles | Sort-Object LastModified -Descending
    
    Write-Host "Found $($saveFiles.Count) save files"
    foreach ($file in $saveFiles) {
        Write-Host "DEBUG: Save file object: $($file.GetType().Name) - Path: $($file.Path)"
    }
    return $saveFiles
}

function Find-EldenRingGameExecutable {
    Write-Host "Auto-detecting Elden Ring game executable..."
    
    $executables = @()
    
    # Common Steam installation paths
    $commonPaths = @(
        "C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING\Game\eldenring.exe",
        "C:\Program Files\Steam\steamapps\common\ELDEN RING\Game\eldenring.exe",
        "C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING\eldenring.exe",
        "C:\Program Files\Steam\steamapps\common\ELDEN RING\eldenring.exe",
        "C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING\ELDEN RING.exe",
        "C:\Program Files\Steam\steamapps\common\ELDEN RING\ELDEN RING.exe",
        "E:\SteamLibrary\steamapps\common\ELDEN RING\Game\eldenring.exe",
        "E:\SteamLibrary\steamapps\common\ELDEN RING\eldenring.exe",
        "E:\SteamLibrary\steamapps\common\ELDEN RING\ELDEN RING.exe",
        "D:\SteamLibrary\steamapps\common\ELDEN RING\Game\eldenring.exe",
        "D:\SteamLibrary\steamapps\common\ELDEN RING\eldenring.exe",
        "D:\SteamLibrary\steamapps\common\ELDEN RING\ELDEN RING.exe",
        "F:\SteamLibrary\steamapps\common\ELDEN RING\Game\eldenring.exe",
        "F:\SteamLibrary\steamapps\common\ELDEN RING\eldenring.exe",
        "F:\SteamLibrary\steamapps\common\ELDEN RING\ELDEN RING.exe"
    )
    
    # Check common paths first
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $executables += [PSCustomObject]@{
                Path = $path
                LastModified = (Get-Item $path).LastWriteTime
            }
            Write-Host "DEBUG: Found Elden Ring at common path: $path"
        }
    }
    
    # Try to get Steam library folders from registry (no admin required)
    try {
        $steamPath = Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -Name "SteamPath" -ErrorAction SilentlyContinue
        if ($steamPath -and $steamPath.SteamPath) {
            $steamInstallPath = $steamPath.SteamPath -replace '/', '\'
            Write-Host "DEBUG: Found Steam path: $steamInstallPath"
            
            # Check main Steam library
            $eldenRingPath = Join-Path $steamInstallPath "steamapps\common\ELDEN RING\Game\eldenring.exe"
            if (Test-Path $eldenRingPath) {
                $executables += [PSCustomObject]@{
                    Path = $eldenRingPath
                    LastModified = (Get-Item $eldenRingPath).LastWriteTime
                }
                Write-Host "DEBUG: Found Elden Ring in main Steam library: $eldenRingPath"
            }
            
            # Check libraryfolders.vdf for additional libraries
            $libraryFoldersPath = Join-Path $steamInstallPath "steamapps\libraryfolders.vdf"
            if (Test-Path $libraryFoldersPath) {
                Write-Host "DEBUG: Found libraryfolders.vdf: $libraryFoldersPath"
                $libraryFoldersContent = Get-Content $libraryFoldersPath -Raw
                
                # Parse library paths from libraryfolders.vdf
                $libraryPaths = @()
                $lines = $libraryFoldersContent -split "`n"
                foreach ($line in $lines) {
                    if ($line -match '^\s*"path"\s*"([^"]+)"') {
                        $libraryPath = $matches[1] -replace '\\\\', '\'
                        $libraryPaths += $libraryPath
                        Write-Host "DEBUG: Found library path: $libraryPath"
                    }
                }
                
                # Check each library for Elden Ring
                foreach ($libraryPath in $libraryPaths) {
                    $eldenRingPath = Join-Path $libraryPath "steamapps\common\ELDEN RING\Game\eldenring.exe"
                    if (Test-Path $eldenRingPath) {
                        $executables += [PSCustomObject]@{
                            Path = $eldenRingPath
                            LastModified = (Get-Item $eldenRingPath).LastWriteTime
                        }
                        Write-Host "DEBUG: Found Elden Ring in library: $eldenRingPath"
                    }
                }
            }
        }
    } catch {
        Write-Host "Could not access Steam registry: $($_.Exception.Message)"
    }
    
    # Remove duplicates and sort by last modified date
    $executables = $executables | Sort-Object Path -Unique | Sort-Object LastModified -Descending
    
    Write-Host "Found $($executables.Count) game executables"
    return $executables
}

function Show-SelectionDialog {
    param(
        [string]$title,
        [string]$message,
        [array]$items,
        [string]$displayProperty = "Path"
    )
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $title
    $form.Size = New-Object System.Drawing.Size(600, 400)
    $form.StartPosition = "CenterParent"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    
    # Message label
    $lblMessage = New-Object System.Windows.Forms.Label
    $lblMessage.Text = $message
    $lblMessage.Location = New-Object System.Drawing.Point(10, 10)
    $lblMessage.Size = New-Object System.Drawing.Size(560, 30)
    $lblMessage.Font = New-UnicodeFont "Segoe UI" 9
    $form.Controls.Add($lblMessage)
    
    # List box
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10, 50)
    $listBox.Size = New-Object System.Drawing.Size(560, 250)
    $listBox.Font = New-UnicodeFont "Segoe UI" 9
    $listBox.SelectionMode = "One"
    
    foreach ($item in $items) {
        Write-Host "DEBUG: Processing item: $($item.GetType().Name)"
        Write-Host "DEBUG: Item properties: $($item.PSObject.Properties.Name -join ', ')"
        
        $displayText = ""
        
        # For save files, show more detailed information
        if ($item.PSObject.Properties.Name -contains "SteamID" -and $item.PSObject.Properties.Name -contains "LastModified") {
            $steamID = $item.SteamID
            $lastModified = $item.LastModified.ToString("yyyy-MM-dd HH:mm:ss")
            $displayText = "$($item.Path) (Steam ID: $steamID, Modified: $lastModified)"
        }
        # For game executables, show last modified date
        elseif ($item.PSObject.Properties.Name -contains "LastModified") {
            $lastModified = $item.LastModified.ToString("yyyy-MM-dd HH:mm:ss")
            $displayText = "$($item.Path) (Modified: $lastModified)"
        }
        # Fallback to Path property
        elseif ($item.PSObject.Properties.Name -contains $displayProperty) {
            $displayText = $item.$displayProperty
        }
        # Ultimate fallback
        else {
            $displayText = $item.ToString()
        }
        
        Write-Host "DEBUG: Display text: $displayText"
        $listBox.Items.Add($displayText)
    }
    
    if ($listBox.Items.Count -gt 0) {
        $listBox.SelectedIndex = 0
    }
    
    $form.Controls.Add($listBox)
    
    # Buttons
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "OK"
    $btnOK.Location = New-Object System.Drawing.Point(400, 320)
    $btnOK.Size = New-Object System.Drawing.Size(80, 30)
    $btnOK.DialogResult = "OK"
    $form.Controls.Add($btnOK)
    
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = New-Object System.Drawing.Point(490, 320)
    $btnCancel.Size = New-Object System.Drawing.Size(80, 30)
    $btnCancel.DialogResult = "Cancel"
    $form.Controls.Add($btnCancel)
    
    $result = $form.ShowDialog()
    
    if ($result -eq "OK" -and $listBox.SelectedIndex -ge 0) {
        return $items[$listBox.SelectedIndex]
    }
    
    return $null
}

function Start-EldenRing {
    Write-Log -languageKey "log_elden_ring_launching"
    
    $gameFound = $false
    
    # First, try the configured game executable
    if ($script:config.GameExecutable -and (Test-Path $script:config.GameExecutable)) {
        try {
            Write-Log -languageKey "log_launching_configured_executable" -Parameters @($script:config.GameExecutable)
            
            # Prepare launch arguments
            $arguments = @()
            if ($script:config.LaunchArguments -and $script:config.LaunchArguments.Trim() -ne "") {
                # Split arguments by spaces, but preserve quoted strings
                $arguments = $script:config.LaunchArguments.Trim() -split ' (?=(?:[^"]*"[^"]*")*[^"]*$)'
                Write-Log "Launch arguments: $($script:config.LaunchArguments.Trim())"
                
                # Check if config file exists (for modengine2)
                $configFile = ".\config_eldenring.toml"
                $fullConfigPath = Join-Path (Split-Path $script:config.GameExecutable -Parent) $configFile
                if (Test-Path $fullConfigPath) {
                    Write-Log "Config file found: $fullConfigPath"
                } else {
                    Write-Log "WARNING: Config file not found: $fullConfigPath"
                    Write-Log "This may cause the executable to fail with exit code -2"
                }
            }
            
            if ($arguments.Count -gt 0) {
                Write-Log "Starting process with arguments: $($arguments -join ' ')"
                Write-Log "Working directory: $(Split-Path $script:config.GameExecutable -Parent)"
                $process = Start-Process -FilePath $script:config.GameExecutable -ArgumentList $arguments -WorkingDirectory (Split-Path $script:config.GameExecutable -Parent) -PassThru
                Write-Log "Process started with ID: $($process.Id)"
            } else {
                Write-Log "Starting process without arguments"
                Write-Log "Working directory: $(Split-Path $script:config.GameExecutable -Parent)"
                $process = Start-Process -FilePath $script:config.GameExecutable -WorkingDirectory (Split-Path $script:config.GameExecutable -Parent) -PassThru
                Write-Log "Process started with ID: $($process.Id)"
            }
            
                    # Check if process is actually running - give it more time for game launchers
                    Start-Sleep -Milliseconds 2000  # Give it more time to start
                    if ($process -and !$process.HasExited) {
                        Write-Log "Process is running successfully"
                        $gameFound = $true
                        Write-Log -languageKey "log_elden_ring_launched_configured"
                    } else {
                        # Check if process exited with a specific code that might indicate success
                        if ($process -and $process.ExitCode -eq 0) {
                            Write-Log "Process completed successfully (exit code 0) - this may be normal for some launchers"
                            $gameFound = $true
                            Write-Log -languageKey "log_elden_ring_launched_configured"
                        } else {
                            Write-Log "ERROR: Configured executable failed to start or exited immediately"
                            if ($process) {
                                Write-Log "Process exit code: $($process.ExitCode)"
                            }
                            Write-Log "This may be due to:"
                            Write-Log "1. Missing config file: .\config_eldenring.toml"
                            Write-Log "2. Invalid arguments: $($script:config.LaunchArguments)"
                            Write-Log "3. Executable issues: $($script:config.GameExecutable)"
                            Write-Log "4. Game already running or launcher behavior"
                            Write-Log "Please check your configuration and try again."
                            # Don't fall back to Steam - user configured a specific executable
                            return
                        }
                    }
        }
        catch {
            Write-Log -languageKey "log_error_launching_configured" -Parameters @($_.Exception.Message)
        }
    }
    
    # If user has configured a custom executable but it failed, don't fall back to Steam
    if (-not $gameFound -and $script:config.GameExecutable -and $script:config.GameExecutable.Trim() -ne "") {
        Write-Log "Configured executable failed to launch. Not falling back to Steam since user specified a custom executable."
        Write-Log "Please check your configuration and try again."
        return
    }
    
    # If no custom executable configured, try common installation paths
    if (-not $gameFound) {
        $possiblePaths = @(
            "C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING\Game\eldenring.exe",
            "C:\Program Files\Steam\steamapps\common\ELDEN RING\Game\eldenring.exe",
            "C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING\eldenring.exe",
            "C:\Program Files\Steam\steamapps\common\ELDEN RING\eldenring.exe",
            "C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING\ELDEN RING.exe",
            "C:\Program Files\Steam\steamapps\common\ELDEN RING\ELDEN RING.exe"
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                try {
                    Write-Log -languageKey "log_launching_elden_ring_from" -Parameters @($path)
                    Start-Process -FilePath $path -WorkingDirectory (Split-Path $path -Parent)
                    $gameFound = $true
                    Write-Log -languageKey "log_elden_ring_launched"
                    break
                }
                catch {
                    Write-Log -languageKey "log_error_launching_elden_ring" -Parameters @($path, $_.Exception.Message)
                }
            }
        }
    }
    
    if (-not $gameFound) {
        # Try to launch via Steam
        try {
            Write-Log -languageKey "log_elden_ring_not_found"
            Start-Process "steam://rungameid/1245620"
            Write-Log -languageKey "log_elden_ring_launched_steam"
            $gameFound = $true
        }
        catch {
            Write-Log -languageKey "log_error_launching_steam" -Parameters @($_.Exception.Message)
        }
    }
    
    if (-not $gameFound) {
        Write-Log -languageKey "log_elden_ring_not_found"
        [System.Windows.Forms.MessageBox]::Show(
            "Could not find Elden Ring installation.`n`nPlease configure the game executable path in the settings, or ensure Elden Ring is installed via Steam.",
            "Elden Ring Not Found",
            "OK",
            "Warning"
        )
    } else {
        # Minimize to tray after launching
        Write-Log -languageKey "log_minimizing_after_launch"
        Hide-MainWindow
    }
}

# Core functions
# Function to cleanup resources on exit
function Cleanup-Resources {
    try {
        if ($script:mutex) {
            $script:mutex.ReleaseMutex()
            $script:mutex.Dispose()
            Write-Host "Mutex released successfully"
        }
    } catch {
        Write-Host "Error releasing mutex: $($_.Exception.Message)"
        Write-Host "This is normal if the application crashed - the system will clean up automatically"
    }
}

# Function to handle application crashes gracefully
function Register-CrashHandlers {
    # Register cleanup on PowerShell exit
    Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
        Cleanup-Resources
    }
    
    # Register cleanup on unhandled exceptions
    $null = Register-ObjectEvent -InputObject ([System.AppDomain]::CurrentDomain) -EventName UnhandledException -Action {
        Write-Host "Application crashed - attempting cleanup..."
        Cleanup-Resources
    }
}

# Function to calculate maximum text width across all languages
function Get-MaxTextWidth {
    param($textKey, $font, $baseFontSize = 9)
    
    $languages = @("en", "es", "fr", "ja", "zh-CN", "ko")
    $maxWidth = 0
    
    foreach ($lang in $languages) {
        $text = Get-Text $textKey $lang
        if ($text) {
            $tempLabel = New-Object System.Windows.Forms.Label
            $tempLabel.Font = New-UnicodeFont $font $baseFontSize
            $tempLabel.Text = $text
            $textSize = $tempLabel.CreateGraphics().MeasureString($text, $tempLabel.Font)
            $maxWidth = [Math]::Max($maxWidth, $textSize.Width)
            $tempLabel.Dispose()
        }
    }
    
    return [Math]::Round($maxWidth + 20)  # Add padding
}

# Function to dynamically size labels based on their text content
function Set-LabelSize {
    param([System.Windows.Forms.Label]$label, [int]$maxWidth = 600)
    
    if ($label -and $label.Text) {
        try {
            # Measure the text to determine appropriate size
            $textSize = $label.CreateGraphics().MeasureString($label.Text, $label.Font)
            $newWidth = [Math]::Max($textSize.Width + 20, 80) # Add padding, minimum 80px
            $newWidth = [Math]::Min($newWidth, $maxWidth) # Cap at maxWidth
            
            # Ensure proper height to prevent text clipping (especially for lowercase 'g', 'j', 'p', 'q', 'y')
            $newHeight = [Math]::Max($textSize.Height + 12, 32) # Much more padding for descenders
            
            # Update the label size without triggering layout updates
            $label.Width = $newWidth
            $label.Height = $newHeight
        } catch {
            # Fallback to minimum size if measurement fails
            $label.Width = 80
            $label.Height = 24
        }
    }
}

function Write-Log {
    param([string]$Message, [string]$languageKey = "", [array]$Parameters = @())
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Store log entry data for translation
    $logEntry = @{
        Timestamp = $timestamp
        LanguageKey = $languageKey
        Parameters = $Parameters
        OriginalMessage = $Message
    }
    $script:logEntries += $logEntry
    
    # If a language key is provided, get the localized message
    if ($languageKey -ne "") {
        $Message = Get-Text $languageKey
    }
    
    # Replace placeholders with parameters if provided
    if ($Parameters.Count -gt 0) {
        for ($i = 0; $i -lt $Parameters.Count; $i++) {
            $Message = $Message -replace "\{$i\}", $Parameters[$i]
        }
    }
    
    $logMessage = "[$timestamp] $Message"
    
    # Write-Host "DEBUG: Write-Log called with message: $logMessage"
    
    # Write to console with proper UTF-8 encoding
    try {
        [System.Console]::WriteLine($logMessage)
    } catch {
        Write-Host $logMessage
    }
    
    # Update log in main form if it exists
    if ($script:mainForm) {
        $logSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "LogSection" }
        if ($logSection) {
            $txtLog = $logSection.Controls | Where-Object { $_.Name -eq "txtLog" }
        if ($txtLog) {
            $txtLog.AppendText("$logMessage`r`n")
            $txtLog.SelectionStart = $txtLog.Text.Length
            $txtLog.ScrollToCaret()
                Write-Host "DEBUG: Log message appended to txtLog control - Text length: $($txtLog.Text.Length)"
            } else {
                Write-Host "DEBUG: txtLog control not found in LogSection"
            }
        } else {
            Write-Host "DEBUG: LogSection not found in main form"
        }
    } else {
        Write-Host "DEBUG: Main form not available for log update"
    }
}

# Function to regenerate log with current language
function Update-LogTranslation {
    if ($script:mainForm) {
        $logSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "LogSection" }
        if ($logSection) {
            $txtLog = $logSection.Controls | Where-Object { $_.Name -eq "txtLog" }
            if ($txtLog) {
                # Clear existing log
                $txtLog.Clear()
                
                # Add header
                $headerText = "=== " + (Get-Text "app_title") + " ===`r`n" + (Get-Text "log_app_started") + "`r`n"
                $txtLog.AppendText($headerText)
                
                # Regenerate all log entries with current language
                foreach ($entry in $script:logEntries) {
                    $message = ""
                    
                    if ($entry.LanguageKey -ne "") {
                        # Use the language key to get translated message
                        $message = Get-Text $entry.LanguageKey
                    } else {
                        # Use original message (for non-translatable messages)
                        $message = $entry.OriginalMessage
                    }
                    
                    # Replace placeholders with parameters if provided
                    if ($entry.Parameters.Count -gt 0) {
                        for ($i = 0; $i -lt $entry.Parameters.Count; $i++) {
                            $message = $message -replace "\{$i\}", $entry.Parameters[$i]
                        }
                    }
                    
                    $logMessage = "[$($entry.Timestamp)] $message"
                    $txtLog.AppendText("$logMessage`r`n")
                }
                
                # Scroll to bottom
                $txtLog.SelectionStart = $txtLog.Text.Length
                $txtLog.ScrollToCaret()
            }
        }
    }
}

function Import-Config {
    $configFile = Join-Path $PSScriptRoot "config.json"
    if (Test-Path $configFile) {
        try {
            $loadedConfig = Get-Content $configFile | ConvertFrom-Json
            # Ensure all required fields exist with defaults
            $script:config = @{
                GameExecutable = if ($loadedConfig.GameExecutable) { $loadedConfig.GameExecutable } else { "" }
                LaunchArguments = if ($loadedConfig.LaunchArguments) { $loadedConfig.LaunchArguments } else { "" }
                SaveFilePath = if ($loadedConfig.SaveFilePath) { $loadedConfig.SaveFilePath } else { "" }
                BackupFolder = if ($loadedConfig.BackupFolder) { $loadedConfig.BackupFolder } else { "" }
                MaxBackups = if ($loadedConfig.MaxBackups) { $loadedConfig.MaxBackups } else { 10 }
                MonitorMode = if ($loadedConfig.MonitorMode) { $loadedConfig.MonitorMode } else { "FileChange" }
                TimerInterval = if ($loadedConfig.TimerInterval) { $loadedConfig.TimerInterval } else { 300 }
                IsRunning = if ($loadedConfig.IsRunning) { $loadedConfig.IsRunning } else { $false }
                Language = if ($loadedConfig.Language) { $loadedConfig.Language } else { "en" }
            }
            Write-Host "Config loaded successfully"
            # Update form controls with loaded config
            if ($script:mainForm) {
                # Find sections
                $gameSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "GameSection" }
                $saveSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "SaveSection" }
                $backupSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "BackupSection" }
                
                # Update game executable text box
                if ($gameSection) {
                    $txtGameExe = $gameSection.Controls | Where-Object { $_.Name -eq "txtGameExe" }
                    if ($txtGameExe) { 
                        $txtGameExe.Text = $script:config.GameExecutable 
                        Write-Host "Loaded GameExecutable: $($script:config.GameExecutable)"
                    }
                    
                    $txtLaunchArguments = $gameSection.Controls | Where-Object { $_.Name -eq "txtLaunchArguments" }
                    if ($txtLaunchArguments) { 
                        $txtLaunchArguments.Text = $script:config.LaunchArguments 
                        Write-Host "Loaded LaunchArguments: $($script:config.LaunchArguments)"
                    }
                }
                
                # Update save file text box
                if ($saveSection) {
                    $txtSaveFile = $saveSection.Controls | Where-Object { $_.Name -eq "txtSaveFile" }
                    if ($txtSaveFile) { 
                        $txtSaveFile.Text = $script:config.SaveFilePath 
                        Write-Host "Loaded SaveFilePath: $($script:config.SaveFilePath)"
                    }
                }
                
                # Update backup folder text box
                if ($backupSection) {
                    $txtBackupFolder = $backupSection.Controls | Where-Object { $_.Name -eq "txtBackupFolder" }
                    if ($txtBackupFolder) { 
                        $txtBackupFolder.Text = $script:config.BackupFolder 
                        Write-Host "Loaded BackupFolder: $($script:config.BackupFolder)"
                    }
                }
                
                # Update monitor mode controls
                $backupSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "BackupSection" }
                if ($backupSection) {
                    $radFileChange = $backupSection.Controls | Where-Object { $_.Name -eq "radFileChange" }
                    $radTimerInterval = $backupSection.Controls | Where-Object { $_.Name -eq "radTimerInterval" }
                    $numTimerInterval = $backupSection.Controls | Where-Object { $_.Name -eq "numTimerInterval" }
                    
                    if ($radFileChange -and $radTimerInterval) {
                        if ($script:config.MonitorMode -eq "FileChange") {
                            $radFileChange.Checked = $true
                            $radTimerInterval.Checked = $false
                        } else {
                            $radFileChange.Checked = $false
                            $radTimerInterval.Checked = $true
                        }
                    }
                    
                    if ($numTimerInterval -and $script:config.TimerInterval) {
                        $numTimerInterval.Value = $script:config.TimerInterval
                    }
                }
            }
            Write-Log -languageKey "log_config_loaded"
        }
        catch {
            Write-Log -languageKey "log_error_loading_config" -Parameters @($_.Exception.Message)
        }
    } else {
        Write-Host "No config file found, using defaults"
        # Config is already initialized with defaults in the global variables section
    }
}

function Save-Config {
    $configFile = Join-Path $PSScriptRoot "config.json"
    try {
        Write-Host "DEBUG: Saving config to $configFile"
        Write-Host "DEBUG: Config contents:"
        $script:config | ConvertTo-Json | Write-Host
        $script:config | ConvertTo-Json | Set-Content $configFile
        Write-Host "DEBUG: Config saved successfully"
    }
    catch {
        Write-Host "DEBUG: Error saving config: $($_.Exception.Message)"
        Write-Log -languageKey "log_error_saving_config" -Parameters @($_.Exception.Message)
    }
}

function Start-FileMonitoring {
    if ($script:config.SaveFilePath -and (Test-Path $script:config.SaveFilePath)) {
        $script:fileWatcher = New-Object System.IO.FileSystemWatcher
        $script:fileWatcher.Path = Split-Path $script:config.SaveFilePath -Parent
        $script:fileWatcher.Filter = Split-Path $script:config.SaveFilePath -Leaf
        $script:fileWatcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
        
        Write-Log "DEBUG: File monitoring setup:"
        Write-Log "  - Watching path: $($script:fileWatcher.Path)"
        Write-Log "  - Filter: $($script:fileWatcher.Filter)"
        Write-Log "  - NotifyFilter: $($script:fileWatcher.NotifyFilter)"
        
        Register-ObjectEvent -InputObject $script:fileWatcher -EventName "Changed" -Action {
            Write-Log "DEBUG: File change detected - setting backupNeeded = true"
            $global:backupNeeded = $true
            Write-Log "DEBUG: backupNeeded set to: $($global:backupNeeded)"
        } | Out-Null
        
        $script:fileWatcher.EnableRaisingEvents = $true
        Write-Log (Get-Text "log_file_monitoring_started")
        Write-Log "DEBUG: FileSystemWatcher is now active and monitoring for changes"
    } else {
        Write-Log "ERROR: Cannot start file monitoring - save file path not configured or file not found"
        Write-Log "  - SaveFilePath: $($script:config.SaveFilePath)"
        Write-Log "  - File exists: $(Test-Path $script:config.SaveFilePath)"
    }
}

function Start-TimerMonitoring {
    $script:timer = New-Object System.Windows.Forms.Timer
    $script:timer.Interval = $script:config.TimerInterval * 1000
    $script:timer.Add_Tick({
        if ($script:config.IsRunning) {
            $global:backupNeeded = $true
        }
    })
    $script:timer.Start()
    Write-Log (Get-Text "log_timer_monitoring_started" $script:config.TimerInterval)
}

function Start-Monitoring {
    if (-not $script:config.SaveFilePath -or -not $script:config.BackupFolder) {
        [System.Windows.Forms.MessageBox]::Show("Please configure save file path and backup folder first.", "Configuration Required", "OK", "Warning")
        return
    }
    
    $script:config.IsRunning = $true
    
    if ($script:config.MonitorMode -eq "FileChange") {
        Start-FileMonitoring
    } else {
        Start-TimerMonitoring
    }
    
    # Update UI button states
    Update-MonitoringButtons
    
    Save-Config
    Write-Log (Get-Text "log_monitoring_started" $script:config.MonitorMode)
}

function Stop-Monitoring {
    $script:config.IsRunning = $false
    
    if ($script:fileWatcher) {
        $script:fileWatcher.EnableRaisingEvents = $false
        $script:fileWatcher.Dispose()
        $script:fileWatcher = $null
    }
    
    if ($script:timer) {
        $script:timer.Stop()
        $script:timer.Dispose()
        $script:timer = $null
    }
    
    # Update UI button states
    Update-MonitoringButtons
    
    Write-Log -languageKey "log_monitoring_stopped"
}

function Update-MonitoringButtons {
    if ($script:mainForm) {
        $controlSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "ControlSection" }
        if ($controlSection) {
            $btnStart = $controlSection.Controls | Where-Object { $_.Name -eq "btnStart" }
            $btnStop = $controlSection.Controls | Where-Object { $_.Name -eq "btnStop" }
            
            if ($btnStart -and $btnStop) {
                if ($script:config.IsRunning) {
                    $btnStart.Enabled = $false
                    $btnStop.Enabled = $true
                    Write-Host "DEBUG: Monitoring started - Start disabled, Stop enabled"
                } else {
                    $btnStart.Enabled = $true
                    $btnStop.Enabled = $false
                    Write-Host "DEBUG: Monitoring stopped - Start enabled, Stop disabled"
                }
            }
        }
    }
}

function Show-HelpDialog {
    try {
        $helpTitle = Get-Text "help_title"
        $helpContentArray = Get-Text "help_content"
        
        # Join the array with newlines
        $helpContent = $helpContentArray -join "`n"
        
        # Create a custom form with scrollable text
        $helpForm = New-Object System.Windows.Forms.Form
        $helpForm.Text = $helpTitle
        $helpForm.Size = New-Object System.Drawing.Size(600, 500)
        $helpForm.StartPosition = "CenterParent"
        $helpForm.FormBorderStyle = "FixedDialog"
        $helpForm.MaximizeBox = $false
        $helpForm.MinimizeBox = $false
        $helpForm.ShowInTaskbar = $false
        
        # Create a rich text box with scroll
        $helpTextBox = New-Object System.Windows.Forms.RichTextBox
        $helpTextBox.Multiline = $true
        $helpTextBox.ScrollBars = "Vertical"
        $helpTextBox.ReadOnly = $true
        $helpTextBox.Text = $helpContent
        $helpTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $helpTextBox.Dock = "Fill"
        $helpTextBox.BackColor = [System.Drawing.Color]::White
        $helpTextBox.SelectionStart = 0
        $helpTextBox.SelectionLength = 0
        
        # Create OK button
        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Text = "OK"
        $okButton.Size = New-Object System.Drawing.Size(75, 25)
        $okButton.Location = New-Object System.Drawing.Point(($helpForm.Width - $okButton.Width - 20), ($helpForm.Height - $okButton.Height - 50))
        $okButton.Anchor = "Bottom, Right"
        $okButton.DialogResult = "OK"
        
        # Add controls to form
        $helpForm.Controls.Add($helpTextBox)
        $helpForm.Controls.Add($okButton)
        
        # Set focus to OK button
        $helpForm.AcceptButton = $okButton
        
        # Show the dialog
        $helpForm.ShowDialog() | Out-Null
        
        # Clean up
        $helpForm.Dispose()
    }
    catch {
        Write-Host "Error showing help dialog: $($_.Exception.Message)"
        # Fallback to simple message box
        [System.Windows.Forms.MessageBox]::Show("Help content is not available in the current language.", "Help", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
}

function Populate-FormControls {
    if ($script:mainForm) {
        Write-Host "DEBUG: Populating form controls with config values..."
        
        # Find sections
        $gameSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "GameSection" }
        $saveSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "SaveSection" }
        $backupSection = $script:mainForm.Controls | Where-Object { $_.Name -eq "BackupSection" }
        
        # Update game executable text box
        if ($gameSection) {
            $txtGameExe = $gameSection.Controls | Where-Object { $_.Name -eq "txtGameExe" }
            if ($txtGameExe) { 
                $txtGameExe.Text = $script:config.GameExecutable 
                Write-Host "DEBUG: Populated GameExecutable: $($script:config.GameExecutable)"
            }
            
            $txtLaunchArguments = $gameSection.Controls | Where-Object { $_.Name -eq "txtLaunchArguments" }
            if ($txtLaunchArguments) { 
                $txtLaunchArguments.Text = $script:config.LaunchArguments 
                Write-Host "DEBUG: Populated LaunchArguments: $($script:config.LaunchArguments)"
            }
        }
        
        # Update save file text box
        if ($saveSection) {
            $txtSaveFile = $saveSection.Controls | Where-Object { $_.Name -eq "txtSaveFile" }
            if ($txtSaveFile) { 
                $txtSaveFile.Text = $script:config.SaveFilePath 
                Write-Host "DEBUG: Populated SaveFilePath: $($script:config.SaveFilePath)"
            }
        }
        
        # Update backup folder text box
        if ($backupSection) {
            $txtBackupFolder = $backupSection.Controls | Where-Object { $_.Name -eq "txtBackupFolder" }
            if ($txtBackupFolder) { 
                $txtBackupFolder.Text = $script:config.BackupFolder 
                Write-Host "DEBUG: Populated BackupFolder: $($script:config.BackupFolder)"
            }
        }
        
        Write-Host "DEBUG: Form controls populated successfully"
    }
}

function Backup-SaveFile {
    Write-Log "DEBUG: Backup-SaveFile called"
    Write-Log "DEBUG: SaveFilePath = $($script:config.SaveFilePath)"
    Write-Log "DEBUG: File exists = $(Test-Path $script:config.SaveFilePath)"
    Write-Log "DEBUG: BackupFolder = $($script:config.BackupFolder)"
    
    if (-not $script:config.SaveFilePath -or -not (Test-Path $script:config.SaveFilePath)) {
        Write-Log -languageKey "log_save_file_not_found" -Parameters @($script:config.SaveFilePath)
        return
    }
    
    if (-not $script:config.BackupFolder) {
        Write-Log -languageKey "log_backup_folder_not_configured"
        return
    }
    
    if (-not (Test-Path $script:config.BackupFolder)) {
        New-Item -ItemType Directory -Path $script:config.BackupFolder -Force | Out-Null
    }
    
    # Enhanced timestamp format with date and time
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($script:config.SaveFilePath)
    $extension = [System.IO.Path]::GetExtension($script:config.SaveFilePath)
    
    # Determine file type for better naming
    $fileType = ""
    if ($extension -eq ".sl2") {
        $fileType = "ER"
    } elseif ($extension -eq ".co2") {
        $fileType = "SC"
    } else {
        $fileType = "SAVE"
    }
    
    # Create backup filename with type and timestamp, keeping original filename at the end
    $backupFileName = "${fileType}_backup_${timestamp}_${fileName}${extension}"
    $backupPath = Join-Path $script:config.BackupFolder $backupFileName
    
    try {
        # Create compressed backup using PowerShell's built-in compression
        $tempBackupPath = $backupPath + ".tmp"
        Copy-Item $script:config.SaveFilePath $tempBackupPath -Force
        
        # Compress the backup file
        $zipPath = $backupPath + ".zip"
        Compress-Archive -Path $tempBackupPath -DestinationPath $zipPath -Force
        
        # Remove the temporary uncompressed file
        Remove-Item $tempBackupPath -Force
        
        $script:lastBackupTime = Get-Date
        
        # Get file sizes for logging
        $originalSize = (Get-Item $script:config.SaveFilePath).Length
        $compressedSize = (Get-Item $zipPath).Length
        $compressionRatio = [math]::Round((1 - $compressedSize / $originalSize) * 100, 1)
        
        # Log with file type information and compression stats
        if ($extension -eq ".sl2") {
            Write-Log -languageKey "log_backup_created_elden_ring" -Parameters @("$backupFileName.zip")
        } elseif ($extension -eq ".co2") {
            Write-Log -languageKey "log_backup_created_seamless_coop" -Parameters @("$backupFileName.zip")
        } else {
            Write-Log -languageKey "log_backup_created" -Parameters @("$backupFileName.zip")
        }
        
        Write-Log "DEBUG: Compression stats - Original: $([math]::Round($originalSize/1MB, 2))MB, Compressed: $([math]::Round($compressedSize/1MB, 2))MB, Saved: $compressionRatio%"
        
        # Clean up old backups - support both .sl2 and .co2 files with new naming format and .zip compression
        $backupFiles = Get-ChildItem $script:config.BackupFolder -Filter "ER_backup_*.zip" | Sort-Object CreationTime -Descending
        $coopBackupFiles = Get-ChildItem $script:config.BackupFolder -Filter "SC_backup_*.zip" | Sort-Object CreationTime -Descending
        $allBackupFiles = @($backupFiles) + @($coopBackupFiles) | Sort-Object CreationTime -Descending
        
        if ($allBackupFiles.Count -gt $script:config.MaxBackups) {
            $filesToDelete = $allBackupFiles | Select-Object -Skip $script:config.MaxBackups
            foreach ($file in $filesToDelete) {
                Remove-Item $file.FullName -Force
                Write-Log -languageKey "log_old_backup_removed" -Parameters @($file.Name)
            }
        }
    }
    catch {
        Write-Log -languageKey "log_error_creating_backup" -Parameters @($_.Exception.Message)
    }
}

function Exit-Application {
    Stop-Monitoring
    Save-Config
    if ($script:notifyIcon) {
        $script:notifyIcon.Visible = $false
        $script:notifyIcon.Dispose()
    }
    [System.Windows.Forms.Application]::Exit()
}

# Initialize application
Import-Languages
Import-Config

# Register crash handlers for graceful cleanup
Register-CrashHandlers

# Set language from config
if ($script:config.Language) {
    Set-Language $script:config.Language
}

New-SystemTrayIcon
New-MainForm

# Timer for checking backup needs - debounce multiple file changes
$backupTimer = New-Object System.Windows.Forms.Timer
$backupTimer.Interval = 60000  # Check every 60 seconds (1 minute) for proper debouncing
$backupTimer.Add_Tick({
    # Debug every 2 minutes to show timer is running
    if ((Get-Date).Minute % 2 -eq 0 -and (Get-Date).Second -eq 0) {
        Write-Log "DEBUG: Backup timer running - backupNeeded = $($global:backupNeeded), IsRunning = $($script:config.IsRunning)"
    }
    
    if ($global:backupNeeded -and $script:config.IsRunning) {
        Write-Log "DEBUG: Backup timer triggered - backupNeeded = true, IsRunning = $($script:config.IsRunning)"
        $global:backupNeeded = $false
        Backup-SaveFile
    }
})
$backupTimer.Start()
Write-Log "DEBUG: Backup timer started - checking every 60000ms for backup requests (1-minute debounce)"

Write-Log (Get-Text "log_app_started")
Write-Log (Get-Text "log_tray_instructions")

# Always show window on startup for configuration and control
Write-Log (Get-Text "log_app_started_showing")
$script:mainForm.Show()
$script:mainForm.WindowState = "Normal"
$script:mainForm.ShowInTaskbar = $true
$script:mainForm.BringToFront()
$script:mainForm.Activate()

# Create all controls AFTER the form is shown and initialized
New-FormControls

# Populate text boxes with loaded config values
Populate-FormControls

# Set initial button states based on config
Update-MonitoringButtons

# Start the application with proper cleanup
try {
    [System.Windows.Forms.Application]::Run()
} finally {
    # Cleanup resources on exit
    Cleanup-Resources
}
